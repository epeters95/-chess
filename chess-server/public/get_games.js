let table = document.getElementById("gameTable");

let modal = document.getElementsByClassName("modal")[0];
let modalCloseBtn = document.getElementById("modalCloseButton");
modalCloseBtn.addEventListener("click", function(event) {
  modal.classList.add("hidden");
})

let movesList = document.getElementById("movesList");


function getGames() {
  let spinner = document.createElement('div');
  spinner.id = "loading";
  spinner.innerHTML = '<div id="loadingspinner"><img src="spinner.gif"></div>';
  document.getElementById("gameTableView").appendChild(spinner);

  fetch("http://localhost:3000/api/games", {
    method: "GET",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json"
    }
  })
  .then(response => response.json())
  .then(function(json) {
    if (json.error === undefined) {
      populateTable(json)
    }
    spinner.classList.add("hidden");
  })
}

function populateTable(json) {
  let htmlString = "";
  let gamesArray = json["games"];
  let maxRows = Math.ceil(gamesArray.length / 3.0);

  // 3-column grid of games
  for (let j = 0; j < maxRows; j++) {

    if (gamesArray.length > 0) {
      htmlString += "<tr>";

      for (let i = 0; i < 3; i++) {

        if (gamesArray.length > 0) {
          let game = gamesArray.shift();
          let view = gameViewHtml(game);
          htmlString += "<td>" + view + "</td>";
        }
      }
      htmlString += "</tr>";
    }
  }
  table.innerHTML = htmlString;
  Array.from(document.getElementsByClassName("getBoard")).forEach(function(el) {
    let id = el.getAttribute("data-id");
    let boardUrl = "http://localhost:3000/api/games/" + id + "/board"
    boardUrl += "#with_history=true"
    el.addEventListener("click", function(event) {
      modal.classList.remove("hidden");
      fetch(boardUrl, {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        }
      })
      .then(response => response.json())
      .then(function(json) {
        if (json.error === undefined) {
          populateGameAndMoves(json);
        } else {
          alert("Error: " + json.error);
        }
      })

    })
  });
}

function populateGameAndMoves(json) {
  // Initialize map variable
  var moveToPiecesMap = {};
  var movesMap = {};
  
  // Populate snapshots of the game at each move
  json["moves"].forEach(function(move, i) {
    let id = 0;
    if (move) {
      id = move.id
    }
    moveToPiecesMap[id] = json["pieces_history"][i];
  })

  showBoardRefresh(json, moveToPiecesMap)
}

function showBoardRefresh(json, moveToPiecesMap, selectedId) {
  setVars(json["game"])
  drawGame()
  // Populate moves sidebar
  drawMoveList(json, moveToPiecesMap, selectedId)
}

function drawMoveList(json, moveToPiecesMap, selectedId) {
  movesList.innerHTML = "";
  let list = document.createElement("table");
  let row;
  json["moves"].forEach(function(move, index) {
    if (!move)
      return;
    function clickFunction(event) {
      event.target.classList.add("selected")
      json["game"]["pieces"] = moveToPiecesMap[move.id];
      showBoardRefresh(json, moveToPiecesMap, move.id)
    }

    // Move number
    let moveCell = document.createElement("td");
    moveCell.innerHTML = "<span style='color:wheat'>" + (1 + Math.floor(move.move_count / 2)) + "</span>"

    // Move notation
    let notationCell = document.createElement("td");
    notationCell.innerHTML = "" + (move.notation || getMoveNotation(move))
    notationCell.setAttribute("data-id", move.id)
    notationCell.addEventListener("click", clickFunction)

    // For white, create a new row
    if (index % 2 === 1) {
      row = document.createElement("tr")
      row.appendChild(moveCell)
      row.appendChild(notationCell)
      list.appendChild(row);

    // Add black to previously created row
    } else {
      row.appendChild(notationCell)
    }

  })
  movesList.appendChild(list);
  if (selectedId) {
    let cell = document.querySelector("[data-id='" + selectedId + "']");
    cell.classList.add("selected");
  }
}

function getMoveNotation(move) {
  // TODO: ensure correct move notation is done serverside and stored
  let piece = JSON.parse(move.piece_str)
  if (move.move_type === "attack") {
    return piece.char + piece.position + " x " + move.new_position
  } else {
    return piece.char + piece.position + " " + move.new_position
  }
}




function gameViewHtml(game) {
  let id = game["id"];
  let name1 = game["white_name"];
  let name2 = game["black_name"];

   + id + "/board";
  let htmlString = "<div class='gameThumbnail' style='width:100%; height:100%'>";

  htmlString += "<div style='width: 90%; height: 90%; margin: auto; position: relative; background-color: rgba(0,0,0,0.2);'>";
  htmlString += "<span><b>" +
                getName(name1) + " vs. " +
                getName(name2) +
                "</b></span>";
  htmlString += "<br><br>"
  htmlString += "<span style='color: white;'>" + game.move_count + " moves</span>";
  htmlString += "<br>";
  htmlString += "<a href='#' class='getBoard' id='getBoard' data-id='" + id + "'>";
  htmlString += "<span>View Game</span>";
  htmlString += "</a>";
  htmlString += "</div>";

  htmlString += "</div>";
  return htmlString;
}

function getName(name) {
  if (name === "") {
    return "Computer";
  }
  return name;
}

getGames();