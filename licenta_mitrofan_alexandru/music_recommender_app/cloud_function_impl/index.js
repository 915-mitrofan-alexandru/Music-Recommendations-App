const functions = require('firebase-functions');
const {onSchedule} = require("firebase-functions/v2/scheduler");
var admin = require("firebase-admin");
const { getFirestore, set, doc } = require('firebase-admin/firestore');
var serviceAccount = require("./serviceAccountKey.json"); // for the firebase admin authentication
const queryString = require("node:querystring");
const axios = require("axios");
const {
  log,
  info,
  debug,
  warn,
  error,
  write,
} = require("firebase-functions/logger");

// for spotify app admin authentication
const appId = process.env['APP_ID'];
const appSecret = process.env['APP_SECRET'];
const redirectUri = process.env['REDIRECT_URI'];
const base64string = process.env['BASE64_STRING'];

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = getFirestore(admin.apps[0]);

exports.makeCustomToken = functions.https.onRequest(async (req, res) => {
  const spotifyToken = req.query.spotifyToken;

  admin.auth().createCustomToken(spotifyToken)
  .then(function(customToken) {
    console.log(customToken);
    res.json({customToken: `${customToken}`});
  })
  .catch(function(error) {
    res.json({result: `makeCustomToken error`});
    console.log('Error creating custom token:', error);
  });

});

exports.logInSpotify = functions.https.onRequest(async (req, res) => {
    const spotifyResponse = await axios.post(
       "https://accounts.spotify.com/api/token",
       queryString.stringify({
          grant_type: "authorization_code",
          code: req.query.code,
          client_id: appId,
          client_secret: appSecret,
          redirect_uri: redirectUri,
       }),
       {
          headers: {
             Authorization: "Basic " + base64string,
          },
       }
    );
    res.json({data: spotifyResponse.data});
})

exports.logInWithRefreshTokenSpotify = functions.https.onRequest(async (req, res) => {
    const spotifyResponse = await axios.post(
       "https://accounts.spotify.com/api/token",
       queryString.stringify({
          grant_type: "refresh_token",
          refresh_token: req.query.refresh_token,
          client_id: appId,
          client_secret: appSecret,
          redirect_uri: redirectUri,
       }),
       {
          headers: {
             Authorization: "Basic " + base64string,
          },
       }
    );
    res.json({data: spotifyResponse.data});
})

exports.getUserDataSpotify = functions.https.onRequest(async (req, res) => {
    const spotifyResponse = await axios.get(
       "https://api.spotify.com/v1/me",
       {
          headers: {
             Authorization: "Bearer " + req.query.access_token,
          },
       });
    res.json({data: spotifyResponse.data});
})

exports.getCrtPlayingSpotify = functions.https.onRequest(async (req, res) => {
    const spotifyResponse = await axios.get(
       "https://api.spotify.com/v1/me/player/currently-playing",
       {
          headers: {
             Authorization: "Bearer " + req.query.access_token,
          },
       });

    res.json({data: spotifyResponse.data});
})

exports.generateNormalRecommendations = onSchedule("every day 01:00", async (event) => {
    var userData = {};
    var itemData = {};
    const userRef = db.collection('users');
    const snap_collection = await userRef.count().get();
    const snapshotSongs = await db.collection('songs').get();
    snapshotSongs.forEach(song => {
        itemData[song.id] = {};
        itemData[song.id]["features"] = song.data();
        itemData[song.id]["users"] = {}
    });
    const snapshotUsers = await db.collection('users').get();
    var cnt = 0;
    snapshotUsers.forEach(async(user) => {
        var usrRatings = user.data().ratings;
        userData[user.id] = {};
        userData[user.id]["genres"] = user.data().genres;
        userData[user.id]["ratings"] = {};
        if (usrRatings != null && usrRatings != 0){
            const snapshotRatings = await db.collection('ratings').where('id', 'in', usrRatings).get();
            snapshotRatings.forEach(rated => {
                userData[user.id]["ratings"][rated.data().song] = rated.data().rating;
            });
        }
        var recommendations = [];
        snapshotSongs.forEach(song =>{
            itemData[song.id]["users"][user.id] = {};
            var song1 = song.id;
            // if the song has not been rated
            if (!Object.keys(userData[user.id]["ratings"]).includes(song1)){
                // if we have ratings

                if (usrRatings != null && usrRatings != 0){
                    // compute similarity coefficient
                    var nom = 0;
                    var denom = 0;
                    // go through rated songs to compute recomm_coefficient
                    Object.entries(userData[user.id]["ratings"]).forEach(([song2, rating2]) => {
                        // feature similarity:
                        var diff = Math.abs(itemData[song1]["features"]["energy"]-itemData[song2]["features"]["energy"]);
                        var energy_sim = 0; // energy similarity
                        if (diff < 10) {
                            energy_sim = 1 - ((diff * diff) / 100);
                        }
                        diff = Math.abs(itemData[song1]["features"]["danceability"]-itemData[song2]["features"]["danceability"]);
                        var danceability_sim = 0; // danceability similarity
                        if (diff < 10) {
                            danceability_sim = 1 - ((diff * diff) / 100);
                        }

                        diff = Math.abs(itemData[song1]["features"]["acousticness"]-itemData[song2]["features"]["acousticness"]);
                        var acousticness_sim = 0; // acousticness similarity
                        if (diff < 10) {
                            acousticness_sim = 1 - ((diff * diff) / 100);
                        }

                        var song_d = itemData[song1]["features"]["genres"].replace(',','');
                        var genres = song_d.split(" ");
                        var c = 0;
                        genres.forEach(genre => {
                            if(itemData[song2]["features"]["genres"].includes(genre)){
                                c += 1;
                            }
                        });
                        var genre_sim = c/genres.length; // genre similarity
                        var similarity = 0.4 * genre_sim + 0.2 * energy_sim + 0.2 * danceability_sim + 0.2 * acousticness_sim;
                        nom += rating2 * similarity;
                        denom += similarity;
                    });
                    var sim_coefficient = 0;
                    if (denom != 0){
                        sim_coefficient = nom / denom;
                    }
                    itemData[song.id]["users"][user.id]["sim_coeff"] = sim_coefficient;
                } // if we don't have ratings, we can't calculate similarities
                else {
                    itemData[song.id]["users"][user.id]["sim_coeff"] = 1;
                }
                // compute genre coeff using the user's prefered genres
                var genres = userData[user.id]["genres"].split(",");
                var c = 0;
                genres.forEach(genre => {
                    if(itemData[song1]["features"]["genres"].includes(genre)){
                        c += 1;
                    }
                });

                var recomm_coeff = (c/genres.length) + itemData[song1]["users"][user.id]["sim_coeff"];
                var morning_coeff = (itemData[song1]["features"]["energy"]/100) * 0.4 + (itemData[song1]["features"]["danceability"]/100) * 0.3 + (1-itemData[song1]["features"]["acousticness"]/100) * 0.3;
                var evening_coeff = 1-morning_coeff;
                var discover_coeff = 1-itemData[song1]["features"]["popularity"]/100;

                recommendations.push([song1, [recomm_coeff, morning_coeff, evening_coeff, discover_coeff]]);
            }
        });
        // sort recommendations by the recomm_coeff that we computed
        recommendations.sort(function (first, second) {
            return second[1][0] - first[1][0];
        });
        var sorted_recs = recommendations.slice(0, 50);
        // update normal genre+features recommendations
        var recommendations = sorted_recs.slice(0, 5);
        var recomm_normal = [];
        recommendations.forEach(rec => {
            recomm_normal.push(rec[0]);
        });

        var rest = sorted_recs.slice(5, 50);
        // update morning and evening recommendations after sorting by coefficient
        var recomm_morning = [];
        var recomm_evening = [];
        rest.sort(function (first, second) {
            return second[1][1] - first[1][1];
        });

        recommendations = rest.slice(0, 5); // morning recommendations
        recommendations.forEach(rec => {
            recomm_morning.push(rec[0]);
        });

        recommendations = rest.slice(40, 45); // evening recommendations
        recommendations.forEach(rec => {
            recomm_evening.push(rec[0]);
        });
        sorted_recs = rest.slice(5, 40);
        var recomm_discover = [];
        sorted_recs.sort(function (first, second) {
            return second[1][3] - first[1][3];
        });

        recommendations = sorted_recs.slice(0, 5); // discovery recommendations
        recommendations.forEach(rec => {
            recomm_discover.push(rec[0]);
        });

        const data = {
           normal_recommendations: recomm_normal,
           morning_recommendations: recomm_morning,
           evening_recommendations: recomm_evening,
           discover_recommendations: recomm_discover
        };

        const addRes = await db.collection('users').doc(user.id).update(data);
        cnt += 1;
        if (cnt == snap_collection.data().count){
            log("Updated normal recommendations for all users");
            return;
        }
    });
})

exports.generateFriendRecommendations = onSchedule("every day 00:00", async (event) => {
        var userData = {};
        const snapshotUsers = await db.collection('users').get();
        const collectionRef = db.collection('users');
        const snap_collection = await collectionRef.count().get();
        var cnt = 0; // count to see when all user computations are done
        await snapshotUsers.forEach(async(user) => {

            // computer average rating of the user
            const userRef = await db.collection('users').doc(user.id).get();
            var usrFriends = userRef.data().friends;
            var usrRatings = userRef.data().ratings;
            // if there are not enough friends or ratings then we can't compute recommendations
            if (usrFriends == null || usrRatings == null || usrFriends.length == 0 || usrRatings.length == 0){
                cnt += 1;
                return;
            }
            var avg = 0;

            userData[user.id] = {};
            userData[user.id]["ratings"] = {};
            const snapshotRatings = await db.collection('ratings').where('id', 'in', usrRatings).get();
            snapshotRatings.forEach(rated => {
                userData[user.id]["ratings"][rated.data().song] = rated.data().rating
                avg += parseInt(rated.data().rating);
            });
            userData[user.id]["average"] = avg/(usrRatings.length);
            cnt += 1;
            if (cnt == snap_collection.data().count){ // all prep data is done
                cnt = 0;
                const snapshot = await db.collection('users').get();
                snapshot.forEach(async(usr) => { // go through all users asynchronously
                    // go through friends and compute similarity + add possible recommendations
                    var possible_songs = [];
                    var crtFriends = usr.data().friends;
                    // if we haven't computed an average, then no recommendations
                    if (crtFriends == null || crtFriends.length == 0){
                        cnt += 1;
                        return;
                    }
                    userData[usr.id]["similarities"] = {};
                    // compute the similarity with each friend
                    crtFriends.forEach( friend =>{
                        if(userData[friend] != null){
                            var ratings = [];
                            // compute by taking the ratings from each commonly rated song
                            Object.entries(userData[friend]["ratings"]).forEach(([song, rating]) => {
                                    if (Object.keys(userData[usr.id]["ratings"]).indexOf(song) !== -1) {
                                        ratings.push([(userData[usr.id]["ratings"][song] - userData[usr.id]["average"]), (rating - userData[friend]["average"])]);
                                    }
                                    else {// possible recommendation = song not listened to yet
                                        if (!possible_songs.includes(song)){
                                            possible_songs.push(song);
                                        }
                                    }
                                })
                            if(ratings.length == 0){
                                userData[usr.id]["similarities"][friend] = 0;
                            }
                            var nom = 0;
                            var denom1 = 0;
                            var denom2 = 0;
                            // compute pearson similarity
                            ratings.forEach(([r1, r2]) => {
                                nom += r1 * r2;
                                denom1 += r1 * r1;
                                denom2 += r2 * r2;
                            })
                            if (denom1 * denom2 == 0){
                                userData[usr.id]["similarities"][friend] = 0;
                            }
                            userData[usr.id]["similarities"][friend] = (nom / (Math.sqrt(denom1) * Math.sqrt(denom2)));
                        }
                    });
                    var recommendations = {};
                    // go through each possible song and compute the coefficient
                    possible_songs.forEach(recomm => {
                        let nom = 0;
                        let denom = 0;
                        crtFriends.forEach( friend => {
                            if (Object.keys(userData[friend]["ratings"]).includes(recomm)){
                                nom += userData[usr.id]["similarities"][friend] * (userData[friend]["ratings"][recomm] - userData[friend]["average"]);
                                denom += Math.abs(userData[usr.id]["similarities"][friend]);
                            }
                        });
                        recommendations[recomm] = userData[usr.id]["average"] + (nom / denom);
                    });
                    var items = Object.keys(recommendations).map(function (key) {
                        return [key, recommendations[key]];
                    });
                    items.sort(function (first, second) {
                        return second[1] - first[1];
                    });
                    var recs = items;
                    if (items.length > 5) {
                        recs = items.slice(0, 5);
                    }
                    var recomM = [];
                    recs.forEach(rec => {
                        recomM.push(rec[0]);
                    })

                    const data = {
                       friend_recommendations: recomM
                    };

                    const addRes = await db.collection('users').doc(usr.id).update(data);
                    cnt +=1;
                    if (cnt == snap_collection.data().count){
                        return;
                    }
                });
            }
        });
})


exports.setGenres = functions.https.onRequest(async (req, res) =>{
    try {
        const data = {
            genres: req.query.genres
        };
        const addRes = await db.collection('users').doc(req.query.id).update(data);
        res.json({status: "done"});
    } catch (err) {
        res.status(500).send(err);
    }
});

exports.addToUsers = functions.https.onRequest(async (req, res) => {
    try {
        const data = {
                  display_name: req.body.display_name,
                  country: req.body.country,
                  access_token: req.body.access_token,
                  refresh_token: req.body.refresh_token,
                  pfp_url: req.body.pfp_url
                };

        var doc = await db.collection('users').doc(req.body.id).get();
        if (doc.exists == true) {
            const addRes = await db.collection('users').doc(req.body.id).update(data);
        }
        else {
            const addRres = await db.collection('users').doc(req.body.id).set(data);
        }

        const userRef = await db.collection('users').doc(req.body.id).get();
                var crtFriends = userRef.data().friends;
                var reqFriends = userRef.data().requests;
                var genresUser = userRef.data().genres;
                if (genresUser == null){
                    genresUser = "";
                }
                var fr_array = [];
                var rq_array = [];
                var crt_rating = {
                    id: ""
                };
                var rated_array = [];
                        var ratings = userRef.data().ratings;
                        if (ratings!= null && ratings.length != 0){
                            const snapshot = await db.collection('ratings').where('id', 'in', ratings).get();
                                                    snapshot.forEach(doc => {
                                                       var rt_data = {
                                                            artist: doc.data().artist,
                                                            title: doc.data().title,
                                                            id: doc.id,
                                                            image: doc.data().image,
                                                            uri: doc.data().uri,
                                                            song: doc.data().song,
                                                            rating: doc.data().rating,
                                                          };
                                                       if (doc.data().song == req.body.song){
                                                          crt_rating = rt_data;
                                                       }
                                                       rated_array.push(rt_data);
                                                    });
                        }

                if (crtFriends != null || crtFriends.length != 0){
                    const fr_snapshot = await db.collection('users').where('id', 'in', crtFriends).get();
                                    fr_snapshot.forEach(doc => {
                                        var fr_data = {
                                           pfp_url: doc.data().pfp_url,
                                           id: doc.id,
                                           display_name: doc.data().display_name,
                                        };
                                        fr_array.push(fr_data);
                                    });
                }

                if (reqFriends != null && reqFriends.length != 0){
                    const req_snapshot = await db.collection('users').where('id', 'in', reqFriends).get();
                                    req_snapshot.forEach(doc => {
                                    var rq_data = {
                                           id: doc.id,
                                           pfp_url: doc.data().pfp_url,
                                           display_name: doc.data().display_name
                                        };
                                        rq_array.push(rq_data);
                                    });
                }

        res.json({genres: genresUser, friends: fr_array, requests: rq_array, rated: rated_array, crt_rating: crt_rating});
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.updateUser = functions.https.onRequest(async (req, res) => {
    try {
        const userRef = await db.collection('users').doc(req.query.id).get();
        var crtFriends = userRef.data().friends;
        var reqFriends = userRef.data().requests;
        var fr_array = [];
        var rq_array = [];
        var rated_array = [];
        var ratings = userRef.data().ratings;
        var crt_rating = {
                            id: ""
                        };
        if (ratings != null && ratings.length != 0) {
            const snapshot = await db.collection('ratings').where('id', 'in', ratings).get();
                    snapshot.forEach(doc => {
                       var rt_data = {
                            artist: doc.data().artist,
                            title: doc.data().title,
                            id: doc.id,
                            image: doc.data().image,
                            uri: doc.data().uri,
                            song: doc.data().song,
                            rating: doc.data().rating,
                          };
                          if (doc.data().song == req.query.song){
                                                        crt_rating = rt_data;
                                                     }
                       rated_array.push(rt_data);
                    });
        }

        if (crtFriends != null && crtFriends.length != 0){
            const fr_snapshot = await db.collection('users').where('id', 'in', crtFriends).get();
                fr_snapshot.forEach(doc => {
                    var fr_data = {
                       pfp_url: doc.data().pfp_url,
                       id: doc.id,
                       display_name: doc.data().display_name,
                    }
                    fr_array.push(fr_data);
                });
        }

        if (reqFriends != null && reqFriends.length != 0){
            const req_snapshot = await db.collection('users').where('id', 'in', reqFriends).get();
                req_snapshot.forEach(doc => {
                var rq_data = {
                       id: doc.id,
                       pfp_url: doc.data().pfp_url,
                       display_name: doc.data().display_name
                    }
                    rq_array.push(rq_data);
                });
        }
        res.json({friends: fr_array, requests: rq_array, rated: rated_array, crt_rating: crt_rating});
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.getCrtUser = functions.https.onRequest(async (req, res) => {
    try {
        const userRef = await db.collection('users').doc(req.query.id).get();
        var usrData = userRef.data();

        res.json({data: usrData});
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.getUserRecommendations = functions.https.onRequest(async (req, res) => {
    try {
        const userRef = await db.collection('users').doc(req.query.id).get();
        const friend_recommendations = userRef.data().friend_recommendations;
        const morning_recommendations = userRef.data().morning_recommendations;
        const evening_recommendations = userRef.data().evening_recommendations;
        const discover_recommendations = userRef.data().discover_recommendations;
        const normal_recommendations = userRef.data().normal_recommendations;

        var friendRec = [];
        if (friend_recommendations != null || friend_recommendations.length != 0){
            for (const song of friend_recommendations) {
                songInfo = await db.collection('songs').doc(song).get();
                friendRec.push(songInfo.data());
            }
        }

        var morningRec = [];
        if (morning_recommendations != null || morning_recommendations.length != 0){
            for (const song of morning_recommendations) {
                songInfo = await db.collection('songs').doc(song).get();
                morningRec.push(songInfo.data());
            }
        }

        var eveningRec = [];
        if (evening_recommendations != null || evening_recommendations.length != 0){
            for (const song of evening_recommendations) {
                songInfo = await db.collection('songs').doc(song).get();
                eveningRec.push(songInfo.data());
            }
        }

        var normalRec = [];
        if (normal_recommendations != null || normal_recommendations.length != 0){
            for (const song of normal_recommendations) {
                songInfo = await db.collection('songs').doc(song).get();
                normalRec.push(songInfo.data());
            }
        }

        var discoverRec = [];
        if (discover_recommendations != null || discover_recommendations.length != 0){
            for (const song of discover_recommendations) {
                songInfo = await db.collection('songs').doc(song).get();
                discoverRec.push(songInfo.data());
            }
        }

        const data = {
            friend: friendRec,
            normal: normalRec,
            morning: morningRec,
            evening: eveningRec,
            discover: discoverRec
        };

        res.json(data);
        return;
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.addToSongs = functions.https.onRequest(async (req, res) => {
    try {
        const data = {
          title: req.body.title,
          artist: req.body.artist,
          genres: req.body.genres,
          year: req.body.year,
          energy: req.body.energy,
          danceability: req.body.danceability,
          liveness: req.body.liveness,
          acousticness: req.body.acousticness,
          speechiness: req.body.speechiness,
          url: req.body.url,
          uri: req.body.uri,
          popularity: req.body.popularity,
          id: req.body.id
        };
        const res = await db.collection('songs').doc(req.body.id).set(data);
        res.json({status: `done`});
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.addRequest = functions.https.onRequest(async (req, res) => {
    try {
        const crt_user = db.collection('users').doc(req.query.crt);
        var doc = await db.collection('users').doc(req.query.requested).get();
        if (doc.exists == false) {
            res.json({answer: "User with this ID doesn't exist"});
            return;
        }
        const requested_user = db.collection('users').doc(req.query.requested);
        doc = await db.collection("users").doc(req.query.crt).get()
        var friends = doc.data().friends;
        if (friends != null && friends.includes(req.query.requested)) {
            res.json({answer: "User already in friends list"});
            return;
        }
        var requested = doc.data().request_sent_to;
                if (requested != null && requested.includes(req.query.requested)) {
                    res.json({answer: "Already sent request to this user"});
                    return;
                }
        const resUsr = await crt_user.update({
            request_sent_to: admin.firestore.FieldValue.arrayUnion(req.query.requested)
        });
        const resReq = await requested_user.update({
            requests: admin.firestore.FieldValue.arrayUnion(req.query.crt)
        });

        res.json({answer: 'Successfully sent request'});
        return;
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.acceptRequest = functions.https.onRequest(async (req, res) => {
    try {
        const crt_user = db.collection('users').doc(req.query.crt);
        const requested_user = db.collection('users').doc(req.query.req);

        const resUsr = await crt_user.update({
            friends: admin.firestore.FieldValue.arrayUnion(req.query.req),
            requests: admin.firestore.FieldValue.arrayRemove(req.query.req)
        });
        const resReq = await requested_user.update({
            friends: admin.firestore.FieldValue.arrayUnion(req.query.crt),
            request_sent_to: admin.firestore.FieldValue.arrayRemove(req.query.crt)
        });

        res.json({answer: 'Successfully accepted request'});
        return;
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.denyRequest = functions.https.onRequest(async (req, res) => {
    try {
        const crt_user = db.collection('users').doc(req.query.crt);
        const requested_user = db.collection('users').doc(req.query.req);

        const resUsr = await crt_user.update({
            requests: admin.firestore.FieldValue.arrayRemove(req.query.req)
        });
        const resReq = await requested_user.update({
            request_sent_to: admin.firestore.FieldValue.arrayRemove(req.query.crt)
        });

        res.json({answer: 'Denied request'});
        return;
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.addRating = functions.https.onRequest(async (req, res) => {
    try {
        const crt_user = db.collection('users').doc(req.body.user);
        const resAdd = await db.collection('ratings').add({
          rating: req.body.rating,
          user: req.body.user,
          song: req.body.song,
          artist: req.body.artist,
          title: req.body.title,
          image: req.body.image,
          uri: req.body.uri
        });
        const resAw = await crt_user.update({
            ratings: admin.firestore.FieldValue.arrayUnion(resAdd.id)
        });
        const crt_doc = db.collection('ratings').doc(resAdd.id);
        const addId = await crt_doc.update({
            id: resAdd.id
        });

        res.json({answer: "Successfully added rating"});
        return;
    } catch (err) {
       res.status(500).send(err);
     }
});

exports.changeRating = functions.https.onRequest(async (req, res) => {
    try {
        const data = {
          rating: req.query.value,
        };
        const updRes = await db.collection('ratings').doc(req.query.id).update(data)
        res.json({answer: "Successfully added rating"});
        return;
    } catch (err) {
       res.status(500).send(err);
     }
});
