// ORIGINAL CODE made by Nex_isDumb cuz PLEASE CYAN YOURE MY LAST HOPE
// HScript Class code written by ItsLJcool :)

import haxe.Log;
import sys.io.File;
import sys.FileSystem;
import funkin.backend.assets.ModsFolder;

import haxe.io.Bytes;
import haxe.io.BytesOutput;
import haxe.io.BytesInput;

import flixel.util.FlxSort;
import funkin.backend.system.Logs;

import haxe.Timer;

class ReplayManager {

    /*
        BLACK = 0;
        DARKBLUE = 1;
        DARKGREEN = 2;
        DARKCYAN = 3;
        DARKRED = 4;
        DARKMAGENTA = 5;
        DARKYELLOW = 6;
        LIGHTGRAY = 7;
        GRAY = 8;
        BLUE = 9;
        GREEN = 10;
        CYAN = 11;
        RED = 12;
        MAGENTA = 13;
        YELLOW = 14;
        WHITE = 15;

        NONE = -1;
    */

    public static var VERSION:Int = 1;
    public static var COMPATABLE_VERSIONS:Array<Int> = [1];

    private static var __disableLogging:Bool = false;
    private static function _log(?logText:Array, ?type:Int) {
        if (__disableLogging) return;
        
        logText ??= [];
        if (logText.length == 0) return;
        type ??= 0;
        logText.insert(0, Logs.logText("[Replay Manager] ", 10));
        Logs.traceColored(logText, type);
    }

    public static var DONT_RECORD_KEYS:Array<KeyCode> = []; // unused ig

    public static var USE_CONDUCTOR:Bool = true;

    private static var FILE_EXT = "CNEREPLAY";

    private static var EVENTS:Array<{keyUp:Bool, key:Int, time:Float, modifier:Int}> = [];
    private static var PLAYBACK_EVENTS:Array<{keyUp:Bool, key:Int, time:Float, modifier:Int}> = [];
    private static var START_TIME:Float = 0;

    public static var PLAYBACK:Bool = false;
    public static var SHOULD_PLAYBACK:Bool = false;
    public static function record() {
        PLAYBACK = false;
        
        current_keys_down = [];
        EVENTS = [];
        
        if (!USE_CONDUCTOR) START_TIME = Timer.stamp();
        window.onKeyDown.add(_keyDown);
        window.onKeyUp.add(_keyUp);
        _log([Logs.logText("Recording Started", -1)]);
    }

    public static function stop() {
        window.onKeyDown.remove(_keyDown);
        window.onKeyUp.remove(_keyUp);
        _log([Logs.logText((!PLAYBACK) ? "Recording Stopped" : "Playback Stopped", -1)]);
        PLAYBACK = false;

        DONT_RECORD_KEYS = [];
    }

    public static function playback() {
        if (!USE_CONDUCTOR) START_TIME = Timer.stamp();
        PLAYBACK = true;
        PLAYBACK_EVENTS = EVENTS.copy();
    }

    public static function saveReplay(path:String, name:String) {
        var export_path = FileSystem.absolutePath() + "/replays/" + ModsFolder.currentModFolder+"/"+path+"/"+name+"."+FILE_EXT;
        var save:BytesOutput = new BytesOutput();
        save.writeInt32(VERSION);
        save.writeByte((USE_CONDUCTOR) ? 1 : 0);
        save.writeInt32(EVENTS.length);
        for (data in EVENTS) {
            save.writeFloat(data.time);
            save.writeInt32(data.key);
            save.writeInt32(data.modifier);
            save.writeByte((data.keyUp) ? 1 : 0);
        }
        var bytes = save.getBytes();
        _log([Logs.logText("Saving replay to ", -1), Logs.logText(export_path, 6), Logs.logText(" (", -1), Logs.logText(CoolUtil.getSizeString(bytes.length), 11), Logs.logText(" size)", -1)]);
        CoolUtil.safeSaveFile(export_path, bytes);
    }

    public static function loadReplay(path:String, name:String):Bool {
        var export_path = FileSystem.absolutePath() + "/replays/" + ModsFolder.currentModFolder+"/"+path+"/"+name+"."+FILE_EXT;
        if (!FileSystem.exists(export_path)) {
            _log([Logs.logText("Failed to load replay from ", -1), Logs.logText(export_path, 6)]);
            return false;
        }
        EVENTS = [];

        var bytes = new BytesInput(File.getBytes(export_path));
        var version = bytes.readInt32();
        if (version != VERSION && !COMPATABLE_VERSIONS.contains(version)) {
            switch (version) { // parse older versions here
                default:
                    _log([
                    Logs.logText("This Replay is ", -1), Logs.logText("Outdated", 12), Logs.logText(" or ", -1), Logs.logText("not Compatable", 6),
                    Logs.logText(", (This Version: ", -1), Logs.logText(version, 6), Logs.logText(" - Current Version: ", -1), Logs.logText(VERSION, 6), Logs.logText(")", -1)
                    ]);
            }
            return false;
        }

        _log([Logs.logText("Loading replay from ", -1), Logs.logText(export_path, 6)]);
        
        var useConductor = bytes.readByte();
        USE_CONDUCTOR = (useConductor == 1);
        var count = bytes.readInt32();
        for (i in 0...count) {
            var time = bytes.readFloat();
            var key = bytes.readInt32();
            var modifier = bytes.readInt32();
            var keyUp = bytes.readByte();
            addEvent(keyUp, key, time, modifier);
        }
        EVENTS.sort((p1, p2) -> { return FlxSort.byValues(FlxSort.DESCENDING, p1.time, p2.time); });
        _log([Logs.logText("Replay Loaded with ", -1), Logs.logText(EVENTS.length, 11), Logs.logText(" Events", -1)]);
        return true;
    }

    private static function get_time() {
        return ((USE_CONDUCTOR) ? Conductor.songPosition : (Timer.stamp() - START_TIME));
    }

    public static function update() {
        if (!PLAYBACK || PLAYBACK_EVENTS.length == 0) return;
        var event = PLAYBACK_EVENTS[0];
        if (event.time > get_time()) return;
        if (event.keyUp) window.onKeyUp.dispatch(event.key, event.modifier);
        else window.onKeyDown.dispatch(event.key, event.modifier);
        
        PLAYBACK_EVENTS.shift();
        // trace("Replay Delay of " + (Conductor.songPosition - event.time) + " ms");
        update(); // to allow for multiple key presses during the same frame or time to act.
    }

    private static var current_keys_down:Array<Int> = [];
    private static function _keyDown(keyCode, _) {
        if (current_keys_down.contains(keyCode)) return;
        current_keys_down.push(keyCode);
        var time = (USE_CONDUCTOR) ? Conductor.songPosition : (Timer.stamp() - START_TIME);
        addEvent(false, keyCode, time, _);
    }
    private static function _keyUp(keyCode, _) {
        current_keys_down.remove(keyCode);
        var time = (USE_CONDUCTOR) ? Conductor.songPosition : (Timer.stamp() - START_TIME);
        addEvent(true, keyCode, time, _);
    }
    
    public static function addEvent(keyUp:Bool, key:Int, time:Float, modifier:Int) { EVENTS.push({keyUp: keyUp, key: key, time: time, modifier: modifier}); }
}