// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

async function initStream() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: true,
      video: true,
      width: "1280",
    });
    document.getElementById("local-video").srcObject = stream;
  } catch (e) {
    console.log(e);
  }
}

let Hooks = {};
Hooks.JoinCall = {
  mounted() {
    initStream();
  },
};

Hooks.InitUser = {
  mounted() {
    addUsersConnection(this.el.dataset.userUuid);
  },
  destroyed() {
    removeUserConnection(this.el.dataset.userUuid);
  },
};

var users = {};

function addUsersConnection(userUuid) {
  if (users[userUuid] === undefined) {
    users[userUuid] = {
      peerConnection: null,
    };
  }
  return users;
}

function removeUserConnection(userUuid) {
  delete users[userUuid];
  return users;
}

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

function createPeerConnection(lv, fromUser, offer) {
  let newPeerConnection = new RTCPeerConnection({
    iceServers: [{ urls: "stun:littlechat.app:3478" }],
  });
  console.log("users: ",users)

  users[fromUser].peerConnection = newPeerConnection;

  localStream
    .getTracks()
    .forEach((track) => newPeerConnection.addTrack(track, localStream));

  if (offer !== undefined) {
    newPeerConnection.setRemoteDescription({ type: "offer", sdp: offer });
    newPeerConnection
      .createAnswer()
      .then((answer) => {
        newPeerConnection.setLocalDescription(answer);
        console.log("Sending this ANSWER to the requester:", answer);
        lv.pushEvent("new_answer", {
          toUser: fromUser,
          description: description,
        });
      })
      .catch((err) => console.log(err));

    newPeerConnection.onicecandidate = async ({ candidate }) => {
      lv.pushEvent("new_ice_candidate", { toUser: fromUser, candidate });
    };

    if (offer === undefined) {
      newPeerConnection.onnegotiationneeded = async () => {
        try {
          newPeerConnection
            .createOffer()
            .then((offer) => {
              newPeerConnection.setLocalDescription(offer);
              console.log("Sending this OFFER to the requester:", offer);
              HTMLBRElement.pushEvent("new_sdp_offer", {
                toUser: fromUser,
                description: offer,
              });
            })
            .catch((err) => console.log(err));
        } catch (e) {
          console.log(e);
        }
      };
    }

    newPeerConnection.ontrack = async (event) => {
      console.log("Track received:", event);
      document.getElementById(fromUser).srcObject = event.streams[0];
    };

    return newPeerConnection;
  }
}

Hooks.HandleOfferRequest = {
  mounted() {
    console.log("new offer request from", this.el.dataset.fromUserUuid)
    let fromUser = this.el.dataset.fromUserUuid
    createPeerConnection(this, fromUser)
  }
}

Hooks.HandleIceCandidateOffer = {
  mounted() {
    let data = this.el.dataset
    let fromUser = data.fromUser
    let iceCandidate = JSON.parse(data.iceCandidate)
    let peerConnection = users[fromUser].peerConnection

    console.log("new ice candidate from", fromUser, iceCandidate)

    peerConnection.addIceCandidate(iceCandidate)
  }
}

Hooks.handleSdpOffer = {
  mounted() {
    let data = this.el.dataset
    let fromUser = data.fromUserUuid
    let sdp = data.sdp

    if(sdp != "") {
      console.log("new sdp OFFER from", data.fromUserUuid, data.sdp)

      createPeerConnection(this, fromUser, sdp)
    }
  }
}

Hooks.HandleAnswer = {
  mount() {
    let data = this.el.dataset
    let fromUser = data.fromUserUuid
    let sdp = data.sdp
    let peerConnection = users[fromUser].peerConnection

    if(sdp != "") {
      console.log("new sdp ANSWER from", fromUser, sdp)
      peerConnection.setRemoteDescription({type: "answer", sdp: sdp})
    }
  }
}

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (info) =>
  topbar.delayedShow(200)
);
window.addEventListener("phx:page-loading-stop", (info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
liveSocket.enableDebug();
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
