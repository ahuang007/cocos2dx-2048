local GameMusic = {}

local isEffectOn = true
local isMusicOn = true
local curMusicFile = nil
function GameMusic.setEffectSwitch(value)
	isEffectOn = value
end

function GameMusic.setMusicSwitch(value)
	isMusicOn = value
end

function GameMusic.setMusicVolume(volume)
	audio.setMusicVolume(volume)
end

function GameMusic.setEffectVolume(volume)
	audio.setSoundsVolume(volume)
end

function GameMusic.playEffect(effectFile, loop)
	if not isEffectOn then return end
    audio.playSound(effectFile, loop)
end

function GameMusic.stopAllEffects()
	audio.stopAllEffects()
end

function GameMusic.playMusic(musicFile, loop)
    curMusicFile = curMusicFile or musicFile
	if not isMusicOn then return end
    audio.playMusic(musicFile, loop)
end

function GameMusic.pauseMusic()
	audio.stopMusic()
end

function GameMusic.stopMusic()
	audio.stopMusic()
	curMusicFile = nil
end

function GameMusic.resumeMusic()
	audio.stopMusic()
	if curMusicFile then
		audio.playMusic(curMusicFile, true)
	end
end

return GameMusic
