import { contestRanklistReorder } from './contest_ranklist_reorder';
import consumer from "../../channels/consumer"

function secsToText(secs) {
  const ss = Math.floor(secs % 60);
  const mm = Math.floor(secs / 60) % 60;
  const hh = Math.floor(secs / 3600);
  return hh + ':' + String(mm).padStart(2, '0') + ':' + String(ss).padStart(2, '0');
}

export function initContestRanklist(data) {
  contestRanklistReorder(data, -1);

  // Note: JavaScript integer allows usec precision timestamp up to Year 2255
  const SLIDER_UNIT = 1000000; // 1 second
  const contest_length = data.timestamps.end - data.timestamps.start;
  const current_stamp = data.timestamps.current - data.timestamps.start;
  //const current_stamp = Math.floor((data.timestamps.current - data.timestamps.start)/2);
  const slider_length = Math.floor(contest_length / SLIDER_UNIT) + 1;
  const slider_thresh = Math.floor(current_stamp / SLIDER_UNIT) + 1;
  const setTimestamp = (stamp) => {
    const text = stamp == -1 ? "Current status" : secsToText(stamp / 1000000);
    contestRanklistReorder(data, stamp);
    $('#ranklist_time').text(text);
  };
  $('#ranklist_time_slider').slider({
    range: 'min',
    min: 0,
    max: slider_length,
    step: 1,
    value: slider_thresh,
    slide: (evt, ui) => {
      if (ui.value > slider_thresh) {
        $('#ranklist_time_slider').slider('value', slider_thresh);
        setTimestamp(-1);
        return false;
      }
      const stamp = ui.value >= slider_thresh ? -1 : ui.value * SLIDER_UNIT;
      setTimestamp(stamp);
    },
    create: (evt, ui) => {
      // TODO: add tick marks for freeze / current
    }
  });
}

export function initContestCable(id) {
  let lastUpdate = 0;
  let requestPending = false;
  consumer.subscriptions.create({
    channel: "RanklistUpdateChannel",
    id: id
  }, {
    received: (data) => {
      if (requestPending) return;
      let now = Date.now();
      if (now >= lastUpdate + 1000) {
        $('#refresh').trigger('click');
        lastUpdate = now;
      } else {
        requestPending = true;
        setTimeout(() => {
          $('#refresh').trigger('click');
          lastUpdate = Date.now();
          requestPending = false;
        }, lastUpdate + 1000 - now);
      }
    },
    connected: () => {
      $('#status-indicator').addClass('online-indicator').removeClass('offline-indicator');
      $('#status-text').text("Live updating");
    },
    disconnected: () => {
      $('#status-indicator').removeClass('online-indicator').addClass('offline-indicator');
      $('#status-text').text("Offline");
    },
  });
}