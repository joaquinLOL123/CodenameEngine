package funkin.mods;

import lime.utils.Log;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;

import haxe.io.Path;
import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;
import lime.media.AudioBuffer;
import lime.graphics.Image;
import lime.net.HTTPRequest;
import lime.text.Font;
import lime.utils.AssetType;
import lime.utils.Bytes;


#if MOD_SUPPORT
import sys.FileStat;
import sys.FileSystem;
import sys.io.File;
import haxe.zip.Reader;
import haxe.zip.Entry;
#end

class ZipFolderLibrary extends AssetLibrary implements ModsAssetLibrary {
    public var zipPath:String;
    public var libName:String;
    public var useImageCache:Bool = false;
    
    #if MOD_SUPPORT
    public var zip:Reader;
    public var assets:Map<String, Entry> = [];
    #end

    public function new(zipPath:String, libName:String) {
        this.zipPath = zipPath;
        this.libName = libName;

        #if MOD_SUPPORT
        zip = new Reader(File.read(zipPath, true));
        var entries = zip.read();
        for(entry in entries) {
            assets[entry.fileName.toLowerCase()] = entry;
        }
        #end

        super();
    }

    #if MOD_SUPPORT
    public var _parsedAsset:String;
    
    public override function getAudioBuffer(id:String):AudioBuffer {
        if (__isCacheValid(cachedAudioBuffers, id))
            return cachedAudioBuffers.get(id);
        else {
            if (!exists(id, "SOUND")) {
                Log.error('ZipFolderLibrary: Audio Buffer at $id does not exist.');
                return null;
            }
            var e = AudioBuffer.fromBytes(unzip(assets[_parsedAsset]));
            cachedAudioBuffers.set(id, e);
            return e;
        }
    }

    public override function getBytes(id:String):Bytes {
        if (__isCacheValid(cachedBytes, id))
            return cachedBytes.get(id);
        else {
            if (!exists(id, "BINARY")) {
                Log.error('ZipFolderLibrary: Bytes at $id does not exist.');
                return null;
            }
            var e = Bytes.fromBytes(unzip(assets[_parsedAsset]));
            cachedBytes.set(id, e);
            return e;
        }
    }

    
    public static function unzip(f:Entry) {
		if (!f.compressed)
			return f.data;
		var c = new haxe.zip.Uncompress(-15);
		var s = haxe.io.Bytes.alloc(f.fileSize);
		var r = c.execute(f.data, 0, s, 0);
		c.close();
		if (!r.done || r.read != f.data.length || r.write != f.fileSize)
			throw "Invalid compressed data for " + f.fileName;
		f.compressed = false;
		f.dataSize = f.fileSize;
		f.data = s;
		return f.data;
	}

    public override function getFont(id:String):Font {
        if (__isCacheValid(cachedFonts, id))
            return cachedFonts.get(id);
        else {
            if (!exists(id, "FONT")) {
                Log.error('ZipFolderLibrary: Font at $id does not exist.');
                return null;
            }
            var e = Font.fromBytes(unzip(assets[_parsedAsset]));
            cachedFonts.set(id, e);
            return e;
        }
    }

    public override function getImage(id:String):Image {
        if (useImageCache && __isCacheValid(cachedImages, id))
            return cachedImages.get(id);
        else {
            if (!exists(id, "IMAGE")) {
                Log.error('ZipFolderLibrary: Image at $id does not exist.');
                return null;
            }
            var e = Image.fromBytes(unzip(assets[_parsedAsset]));
            if (useImageCache) cachedImages.set(id, e);
            return e;
        }
    }

    public function __parseAsset(asset:String):Bool {
        var prefix = 'assets/$libName/';
        if (!asset.startsWith(prefix)) return false;
        _parsedAsset = asset.substr(prefix.length).toLowerCase();
        return true;
    }

    public function __isCacheValid(cache:Map<String, Dynamic>, asset:String) {
        if (cache.exists(asset)) return true;
        return false;
    }
    
    public override function exists(asset:String, type:String):Bool { 
        if(!__parseAsset(asset)) return false;

        return assets[_parsedAsset] != null;
    }

    private function getAssetPath() {
        return _parsedAsset;
    }

    public function getFiles(folder:String):Array<String> {
        // TODO
        return [];
    }
    #end
}