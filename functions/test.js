const { Firestore } = require("@google-cloud/firestore");
scraper = require("./scraper");

// Create a new client
const firestore = new Firestore();

async function addSeason(number, eps, years) {
  await firestore.collection("seasons").doc(String(number)).set({
    years: years,
  });
  episodeCol = firestore.collection("seasons").doc(String(number)).collection("episodes");
  for (i = eps["start"]; i < eps["end"] + 1; i++) {
    episodeCol.add({number: i});
  }
}

//episodes = { start: 7816, end: 7817 };
//addSeason(35, episodes, "2018-2019");


async function test() {
    snapshot = await firestore.doc('/seasons/35/episodes/gPApFbv7paXLGLo6lx1j').get();
    scraper.scrapeJArchive(snapshot);
    return true;
}
test();


