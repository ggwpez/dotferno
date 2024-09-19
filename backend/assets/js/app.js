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
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import darkModeHook from "../vendor/dark_mode"

function formatBigNumber(n) {
  if (n > 1_000_000) {
    return (n / 1_000_000).toFixed(0) + "M"
  } else if (n > 1_000) {
    return (n / 1_000).toFixed(0) + "K"
  } else {
    return n
  }
}

let Hooks = {}
Hooks.Chart = {
  mounted() {
    const chartConfig = JSON.parse(this.el.dataset.config)
    const seriesData = JSON.parse(this.el.dataset.series)
    const categoriesData = JSON.parse(this.el.dataset.categories)

    const options = {
      series: seriesData,
      tooltip: {
        x: {
            format: "MMM yyyy"
           }
         },
      chart: Object.assign({
        background: 'transparent',
        zoom: {
          enabled: false,
        },
      }, chartConfig),
      xaxis: {
        type: 'datetime',
        categories: categoriesData,
        decimalsInFloat: 0,
        datetimeFormatter: {
          day: 'dd MMM',
          hour: 'HH:mm',
        },
      },
      yaxis: {
        decimalsInFloat: 0,
        labels: {
          formatter: formatBigNumber,
        }
      },
      colors: ['#E6007A'],
      fill: {
        opacity: 1.0,
      },
      stroke: {
        width: 2,
        opacity: 1.0,
      },
      theme: {
        mode: 'dark', 
      }
    }

    const chart = new ApexCharts(this.el, options);
    chart.render();
    let id = `update-dataset-${this.el.id}`;
    console.log(`Subscribing to ${id}`)
    
    this.handleEvent(id, data => {
      console.log(`Received ${id} event`)
      chart.updateSeries(data.dataset)
    })
  }
}

Hooks.DarkThemeToggle = darkModeHook

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
