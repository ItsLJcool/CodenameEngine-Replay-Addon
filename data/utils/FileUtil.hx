//a
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import openfl.display.BitmapData;

function copyFolder(path:String, destPath:String, ?exclude:Array<String>, ?onComplete:Void->Void, ?onError:Void->Void, ?onProgress:Float->Void = null) {
    var exclude = exclude ?? [];
    for (item in [".git", ".gitignore", ".github", ".vscode", ".gitattributes"]) exclude.push(item);
    var complete = onComplete ?? () -> return;
    var failed = onError ?? () -> return;
    var progress = onProgress ?? (p, max) -> return;

    CoolUtil.addMissingFolders(path);
    CoolUtil.addMissingFolders(destPath);
    function precheckFolders(input_path:String, input_destPath:String) {
        var folders = [];
        for (folder in FileSystem.readDirectory(input_path)) {
            if (exclude.contains(folder)) continue;
            if (FileSystem.isDirectory(input_path+"/"+folder)) {
                folders.push({ folder: input_destPath+"/"+folder, });
                folders = folders.concat(precheckFolders(input_path+"/"+folder, input_destPath+"/"+folder));
            }
            else folders.push({
                fPath: input_path+"/"+folder,
                fDest: input_destPath+"/"+folder,
            });
        }
        return folders;
    }
    var folders = precheckFolders(path, destPath);
    var copied = 0;
    progress(0, folders.length);
    for (data in folders) {
        if (data.folder != null) {
            CoolUtil.addMissingFolders(data.folder);
            progress((copied++)/folders.length, folders.length);
            continue;
        }
        try {
            File.copy(data.fPath, data.fDest);
        }
        catch(e:Error) {
            trace("Failed to copy file: " + e);
            failed(e);
        }
        progress((copied++)/folders.length, folders.length);
    }
    progress(1, folders.length);
    complete();
}

function loadImageFromUrl(url:String, ?onComplete:BitmapData->Void, ?onError:Void->Void) {
    var error = onError ?? () -> return;
    var complete = onComplete ?? () -> return;
    try {
        BitmapData.loadFromFile(url).onComplete(function(bitmap:BitmapData) {
            complete(bitmap);
        });
    } catch(e:Error) {
        trace("Failed to load image from url: " + e);
        error(e);
    }
}