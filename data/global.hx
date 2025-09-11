//a
import Type;

import ReplayManager;

import funkin.options.OptionsMenu;

static var REPLAY_MANAGER:ReplayManager = ReplayManager;

function new() {
    FlxG.save.data.recordEnabled ??= false;
}

function update() {
    REPLAY_MANAGER.update();
}

function preStateSwitch() {
    if (Type.getClassName(Type.getClass(FlxG.game._requestedState)) == PlayState || Type.getClassName(Type.getClass(FlxG.game._requestedState)) == OptionsMenu) return;
    REPLAY_MANAGER.SHOULD_PLAYBACK = false;
}