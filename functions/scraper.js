const puppeteer = require("puppeteer");
const firestore = require("@google-cloud/firestore");
const functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp();

async function getRound(page, round) {
  let clueInfo = await page.evaluate(async (round) => {
    let clues = Array.from(document.querySelectorAll("#" + round + " .clue"));
    let infoList = [];
    let value;
    let multiplier = round === "jeopardy_round" ? 200 : 400;
    for (i = 0; i < clues.length; i++) {
      if (!clues[i].querySelector(".clue_text")) {
        infoList.push({
          value: 0,
          question: "",
          answer: "",
          DD: false,
        });
        continue;
      }
      let isDD = !!clues[i].querySelector(".clue_value_daily_double");
      if (!isDD) {
        value = parseInt(
          clues[i].querySelector(".clue_value").innerText.replace("$", "")
        );
      } else {
        id = clues[i].querySelector(".clue_text").id;
        value = id[id.length - 1] * multiplier;
      }
      let question = clues[i].querySelector(".clue_text").innerText;
      let element = clues[i].querySelector("div");
      element.addEventListener("mouseover", function () {
        console.log("Event triggered");
      });

      let event = new MouseEvent("mouseover", {
        view: window,
        bubbles: true,
        cancelable: true,
      });

      element.dispatchEvent(event);
      let answer = clues[i].querySelector(".correct_response").innerText;
      infoList.push({
        value: value,
        question: question,
        answer: answer,
        DD: isDD,
      });
    }
    return infoList;
  }, round);
  round_info = {};
  missing_list = {};
  let multiplier = round === "jeopardy_round" ? 200 : 400;
  for (i = 0; i < categories[round].length; i++) {
    category_clue_info = {};
    category_list_clue_info = {};
    let missing_info = [];
    for (j = 0; j < 5; j++) {
      clue = clueInfo[j * 6 + i];
      category_clue_info[String(multiplier*(j+1))] = clue;
      category_list_clue_info[String(j + 1)] = clue;
      if (clue['value'] == 0) {
        missing_info.push(multiplier*(j+1));
      }
    }
    round_info[categories[round][i]] = {
      clues: category_clue_info,
      comments: category_comments[round][i],
      missing: missing_info
    };
    category_list.push(category_list_clue_info);
    if (missing_info.length > 0) {
      missing_list[categories[round][i]] = missing_info;
    }
  }
  return {'round': round_info, 'list': category_list, 'missing': missing_list};
}

async function scrapeJArchive(snapshot, context) {
  let season = 35; //context.params.seasonNumber;
  let data = snapshot.data();
  let episode = data["number"];
  let doc = snapshot.ref;
  const browser = await puppeteer.launch({ headless: true, slowMo: 250 });
  const page = await browser.newPage();
  await page.goto("http://www.j-archive.com/showseason.php?season=" + season);
  let episodeData = {};
  let episodeInfo = await page.evaluate((episode) => {
    let links = Array.from(document.querySelectorAll("a"));
    let index = links
      .map((x) => x.innerText.includes(episode))
      .findIndex((e) => e === true);

    return {
      link: links[index].href,
      details:
        links[index].parentElement.nextElementSibling.nextElementSibling
          .innerText,
      date: links[index].innerText.split("aired")[1],
    };
  }, episode);
  let episodeLink = episodeInfo["link"];
  console.log(episodeLink);
  let episodeDetails = episodeInfo["details"];
  await page.goto(episodeLink);
  let single_categories = await page.evaluate(() =>
    Array.from(document.querySelectorAll("#jeopardy_round .category")).map(
      (e) => e.querySelector(".category_name").innerText
    )
  );
  let single_category_comments = await page.evaluate(() =>
    Array.from(document.querySelectorAll("#jeopardy_round .category")).map(
      (e) => e.querySelector(".category_comments").innerText
    )
  );
  let double_categories = await page.evaluate(() =>
    Array.from(
      document.querySelectorAll("#double_jeopardy_round .category")
    ).map((e) => e.querySelector(".category_name").innerText)
  );
  let double_category_comments = await page.evaluate(() =>
    Array.from(
      document.querySelectorAll("#double_jeopardy_round .category")
    ).map((e) => e.querySelector(".category_comments").innerText)
  );
  let final_category = await page.evaluate(
    () =>
      document.querySelector("#final_jeopardy_round .category .category_name")
        .innerText
  );
  let final_category_comments = await page.evaluate(() =>
    Array.from(
      document.querySelectorAll("#final_jeopardy_round .category")
    ).map((e) => e.querySelector(".category_comments").innerText)
  );
  categories = {
    jeopardy_round: single_categories,
    double_jeopardy_round: double_categories,
    final_jeopardy_round: final_category,
  };
  category_comments = {
    jeopardy_round: single_category_comments,
    double_jeopardy_round: double_category_comments,
    final_jeopardy_round: final_category_comments,
  };

  episodeData["details"] = episodeDetails;
  episodeData["categories"] = categories;
  episodeData["date"] = episodeInfo["date"];
  category_list = [];
  let jeopardy_clues = await getRound(page, "jeopardy_round");
  let double_jeopardy_clues = await getRound(page, "double_jeopardy_round");
  episodeData['jeopardy_round'] = jeopardy_clues['round'];
  episodeData['double_jeopardy_round'] = double_jeopardy_clues['round'];
  category_list.push(jeopardy_clues['list']);
  category_list.push(double_jeopardy_clues['list']);
  let FJClue = await page.evaluate(async () => {
    let clue = document.querySelector("#clue_FJ");
    let category = document.querySelector("#final_jeopardy_round .category");
    question = clue.innerText;
    let element = category.querySelector("div");
    element.addEventListener("mouseover", function () {
      console.log("Event triggered");
    });

    let event = new MouseEvent("mouseover", {
      view: window,
      bubbles: true,
      cancelable: true,
    });

    element.dispatchEvent(event);
    let answer = clue.querySelector(".correct_response").innerText;
    return { question: question, answer: answer };
  });
  episodeData["final_jeopardy_round"] = {
    category: final_category,
    clue: FJClue,
  };
  episodeData['missing'] = {...jeopardy_clues['missing'], ...double_jeopardy_clues['missing']};

  //console.log(episodeData);
  doc.update(episodeData);
  return true;
}
exports.scrapeJArchive = scrapeJArchive;

exports.triggerScrapeJArchive = functions.firestore
  .document("seasons/{seasonNumber}/episodes/{episodeNumber}")
  .onCreate((snapshot, context) => {
    scrapeJArchive(snapshot, context);
  });
