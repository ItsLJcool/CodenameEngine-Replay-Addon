//a
import funkin.backend.scripting.MultiThreadedScript;

import funkin.options.TreeMenuScreen;
import funkin.options.type.Checkbox;
import funkin.options.type.TextOption;
import funkin.options.type.Separator;
import funkin.options.type.OptionType;
import funkin.options.type.PortraitOption;

import funkin.backend.utils.ZipUtil;

import funkin.backend.assets.ModsFolder;
import funkin.backend.utils.NativeAPI;
import funkin.backend.utils.FileAttribute;

import funkin.backend.system.Flags;

import funkin.editors.ui.UISliceSprite;

import funkin.menus.ui.Alphabet;
import funkin.menus.ui.AlphabetAlignment;
import funkin.menus.ui.effects.WaveEffect;

import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;

import Date;

class BuildData {
    
    public static var replay_folder:String = FileSystem.absolutePath() + "/replays/"+ModsFolder.currentModFolder+"/";

    public static function build_nothing() {
        return [{
            type: TextOption,
            name: "No Recordings Found",
            desc: "You have no recordings for this mod!",
            color: FlxColor.YELLOW,
            callback: () -> {}
        }];
    }

    public static function playReplay(name:String, diff:String, ?variation:String) {
        REPLAY_MANAGER.SHOULD_PLAYBACK = true;

        PlayState.loadSong(name, diff, variation);
        FlxG.switchState(new PlayState());
    }
    public static function generate() {
        if (!FileSystem.exists(replay_folder)) return build_nothing();

        function generate_folders(path:String, ?depth:Int) {
            var depth = (depth ?? 0);
            var children = [];
            var current_song = "";
            var current_difficulty = "";
            for (item in FileSystem.readDirectory(path)) {
                var __path = path+item;
                if (!FileSystem.isDirectory(__path)) {
                    if (Path.extension(__path) != REPLAY_MANAGER.FILE_EXT) continue;
                    var data = __path.split("/").pop().split(".").shift().split(" ");
                    var date = data[0];
                    var time = StringTools.replace(data[1], "-", ":");
                    var date = Date.fromString(date+" "+time);
                    var hours = date.getHours() % 12;
                    var minutes = date.getMinutes();
                    var seconds = date.getSeconds();
                    if (minutes < 10) minutes = "0"+minutes; if (seconds < 10) seconds = "0"+seconds;
                    var time = date.getDay()+ "/"+date.getMonth()+"/"+date.getFullYear()+" @ "+hours+":"+minutes+":"+seconds;
                    children.push({
                        type: TextOption,
                        name: StringTools.replace(StringTools.replace(time, REPLAY_MANAGER.FILE_EXT, ""), "@", "-"),
                        desc: "Recorded at "+time,
                        callback: (child) -> {
                            var lol = data.join(" ");
                            var bruh = __path.split(lol).shift();
                            var kms = __path.split("/"); kms.pop();
                            var diffOrVariation = kms.pop();
                            var nameOrDiff = kms.pop();
                            var nullOrName = kms.pop();

                            var path = (depth == 3) ? nullOrName+"/"+nameOrDiff+"/"+diffOrVariation : nullOrName+"/"+diffOrVariation;
                            var valid = REPLAY_MANAGER.loadReplay(path, lol);
                            if (!valid) {
                                child.locked = true;
                                child.__text.color = 0x770000;
                                return;
                            }
                            if (depth == 3) BuildData.playReplay(nullOrName, nameOrDiff, diffOrVariation);
                            else BuildData.playReplay(nameOrDiff, diffOrVariation);
                        }
                    });
                    continue;
                }
                children.push({
                    type: TreeMenuScreen,
                    name: item,
                    desc: (depth > 0) ? "Difficulty" : "Song",
                    color: (depth > 0) ? FlxColor.LIME : null,
                    children: generate_folders(__path+"/", depth+1),
                });
            }
            return children;
        }

        var top = generate_folders(replay_folder);
        var checking = top.filter(info -> (info.type == TreeMenuScreen && info.children.length > 0));
        if (top.length == 0) return build_nothing();
        
        function recursive_variationCheck(children:Array<Dynamic>, ?depth:Int = 0) {
            var depth = (depth ?? 0);
            for (idx=>item in children) {
                if (item.type == TreeMenuScreen) {
                    if (depth == 2) {
                        item.color = FlxColor.YELLOW;
                        item.desc = "Variation Difficulty";
                        continue;
                    }
                    recursive_variationCheck(item.children, depth+1);
                    continue;
                }
            }
        }
        recursive_variationCheck(top);

        return top;
    }
}

function create() {
    addMenu(new TreeMenuScreen("View Replays", "", null, parseData(BuildData.generate())));
}

function parseData(data:Array<Dynamic>) {
    var children = [
        for (info in data)  {
            switch (info.type) {
                case TreeMenuScreen: new TextOption(info.name, info.desc, " >", () -> addMenu(new TreeMenuScreen(info.name, info.desc, null, parseData(info.children) ) ));
                case Checkbox:
                    var box = new Checkbox(info.name, info?.desc ?? "", null);
                    box.checked = info?.checked ?? false;
                    box;
                case Separator: new Separator(info.height);
                case TextOption: new TextOption(info.name, info.desc, info.suffix);
                case PortraitOption:
                    var port = new PortraitOption(info.name, info.desc, null, FlxG.bitmap.add(Paths.image(info.icon.name)), (info.icon?.size ?? 96), (info.icon?.usePortrait ?? false));
                    port?.portrait?.x += (info.icon?.offset?.x ?? 0);
                    port?.portrait?.y += (info.icon?.offset?.y ?? 0);
                    port;
            }
        }
    ];
    for (idx=>info in data) {
        var child = children[idx];
        if (!(child is OptionType)) continue;
        if (!(info.type == TreeMenuScreen)) child.selectCallback = () -> {
            switch (info.type) {
                case Checkbox: info.checked = child.checked; info.locked = child.locked;
            }
            if (info.callback != null) info.callback(child, children);
        }
        if (info.type != Separator && info.locked != null) child.locked = info.locked;
        if (info.color != null) child.__text.color = info.color;
        if (info.onGenerate != null) info.onGenerate(child, children);
    }
    return children;
}

function update(elapsed:Float) {
    
}