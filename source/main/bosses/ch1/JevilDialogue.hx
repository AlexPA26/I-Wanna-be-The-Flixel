package main.bosses.ch1;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import main.ChapterState;

class JevilDialogue extends FlxGroup
{
    static inline var BOX_WIDTH:Int = 865;
    static inline var BOX_HEIGHT:Int = 210;
    static inline var LETTER_INTERVAL:Float = 0.03;
    static inline var TEXT_PADDING:Int = 25;
    static inline var FONT_SIZE:Int = 36;

    var parentState:ChapterState;
    var box:FlxSprite;
    var textField:FlxText;

    var lines:Array<String> = [];
    var lineIndex:Int = 0;
    var charIndex:Int = 0;
    var typing:Bool = false;
    var dialogueActive:Bool = false;
    var typeTimer:FlxTimer;
    var onComplete:Void->Void;

    public function new(parentState:ChapterState)
    {
        super();
        this.parentState = parentState;

        box = new FlxSprite(0, 0);
        box.loadGraphic(AssetPaths.jevil_dialogue_box__png, false);
        box.x = (FlxG.width - BOX_WIDTH) / 2;
        box.y = FlxG.height - BOX_HEIGHT - 45;
        box.scrollFactor.set(0, 0);
        add(box);

        textField = new FlxText(box.x + TEXT_PADDING, box.y + TEXT_PADDING, BOX_WIDTH - (TEXT_PADDING * 2), "");
        textField.setFormat("assets/fonts/deltarune.otf", FONT_SIZE, FlxColor.WHITE, LEFT, FlxTextBorderStyle.NONE);
        textField.lineSpacing = -10;
        textField.scrollFactor.set(0, 0);
        textField.x += 25;
        add(textField);

        visible = false;
    }

    public function say(dialogueLines:Array<String>, onDone:Void->Void):Void
    {
        lines = dialogueLines;
        lineIndex = 0;
        onComplete = onDone;
        dialogueActive = true;
        visible = true;
        startLine();
    }

    function startLine():Void
    {
        if (lineIndex < 0 || lineIndex >= lines.length || lines[lineIndex] == null)
        {
            finish();
            return;
        }

        charIndex = 0;
        textField.text = "";
        typing = true;
        tickLetter();
    }

    function tickLetter():Void
    {
        if (!dialogueActive || lineIndex >= lines.length) return;

        var currentLine = lines[lineIndex];

        if (charIndex >= currentLine.length)
        {
            typing = false;
            return;
        }

        charIndex++;
        textField.text = currentLine.substr(0, charIndex);
        FlxG.sound.play(AssetPaths.jevil_talk__ogg, 0.75, false);

        if (charIndex < currentLine.length)
        {
            typeTimer = new FlxTimer().start(LETTER_INTERVAL, function(_)
            {
                tickLetter();
            });
        }
        else
        {
            typing = false;
        }
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if (!dialogueActive) return;

        if (InputManager.justPressed(JEVIL_SKIP_DIALOGUE))
        {
            if (typing)
            {
                if (typeTimer != null) typeTimer.cancel();

                var currentLine = lines[lineIndex];
                while (charIndex < currentLine.length)
                {
                    charIndex++;
                    textField.text = currentLine.substr(0, charIndex);
                }
                typing = false;
            }
            else
            {
                lineIndex++;
                if (lineIndex >= lines.length)
                {
                    finish();
                }
                else
                {
                    startLine();
                }
            }
        }
    }

    function finish():Void
    {
        dialogueActive = false;
        visible = false;

        if (typeTimer != null)
        {
            typeTimer.cancel();
            typeTimer = null;
        }

        var cb = onComplete;
        onComplete = null;
        if (cb != null) cb();
    }

    override public function destroy():Void
    {
        if (typeTimer != null)
        {
            typeTimer.cancel();
            typeTimer = null;
        }
        super.destroy();
    }
}
