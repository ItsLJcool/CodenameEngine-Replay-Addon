//a
if (PlayState.chartingMode) return disableScript();
import Date;
import funkin.backend.system.Logs;
if (REPLAY_MANAGER.SHOULD_PLAYBACK) {
    var prev_autoPause = FlxG.autoPause;
    var prev_validScore = PlayState.instance.validScore;
    PlayState.instance.validScore = FlxG.autoPause = false;
    if (REPLAY_MANAGER.USE_CONDUCTOR) REPLAY_MANAGER.playback();
    else function onSongStart() { REPLAY_MANAGER.playback(); }
    function destroy() {
        PlayState.instance.validScore = prev_validScore;
        FlxG.autoPause = prev_autoPause;
        REPLAY_MANAGER.stop();
    }

    if (REPLAY_MANAGER.USE_CONDUCTOR) function onGamePause(e) {
        
        if (REPLAY_MANAGER.PLAYBACK_EVENTS.length == 0){
            REPLAY_MANAGER._log([Logs.logText("Resyncing Vocals...", -1)]);
            return resyncVocals();
        }
        e.cancel();
    }

    var events_ended:Bool = false;
    function update(elapsed) {
        if (events_ended) return;
        if (REPLAY_MANAGER.PLAYBACK_EVENTS.length != 0) return;
        events_ended = true;
        trace("Events Ended");
    }

    return;
}
if (!FlxG.save.data.recordEnabled) return;

if (REPLAY_MANAGER.USE_CONDUCTOR) REPLAY_MANAGER.record();
else function onSongStart() { REPLAY_MANAGER.record(); }

function onSongEnd() {
    REPLAY_MANAGER.stop();
    var name = StringTools.replace(Date.now().toString(), ":", "-");
    var folder = PlayState.SONG.meta.name+"/"+PlayState.difficulty;
    if (PlayState.variation != null) folder += "/"+PlayState.variation;
    REPLAY_MANAGER.saveReplay(folder, name);
}