using System;
using System.IO;
using System.Linq;
using VideoPreviewMaker;

var ffmpeg = new Ffmpeg();
var ffprobe = new Ffprobe();

if(!ffmpeg.Exists())
{
    Console.WriteLine("This application relies on 'ffmpeg.exe'. Please ensure ffmpeg is installed in `C:/tools`");
    return;
}

if(!ffprobe.Exists())
{
    Console.WriteLine("This application relies on 'ffprobe.exe'. Please ensure ffmpeg is installed in `C:/tools`");
    return;
}

Console.Clear();

var videoFile = args.FirstOrDefault();

if(videoFile is null || !File.Exists(videoFile))
{
    Console.WriteLine($"Could not find the video file '{videoFile}'. Make sure you run this application with a valid video file path as the first argument.");
    return;
}

ConsoleExtensions.WriteLineInColor("Getting video's frames count...");
var frames = ffprobe.GetVideoFramesCount(videoFile);

var skipSize = (frames - 1) / 4;
var offset = skipSize / 2;

var frameFiles = new string[4];

for(var i = 1; i < frameFiles.Length + 1; i++)
{
    Console.Clear();
    ConsoleExtensions.WriteLineInColor($"Getting video frames ({i}/{frameFiles.Length})");
    ConsoleExtensions.WriteLineInColor("This may take a long time depending on the video's length and resolution...\n", ConsoleColor.DarkCyan);
    ConsoleExtensions.Progress(Console.WindowWidth - 5, i - 1, frameFiles.Length);
    frameFiles[i - 1] = ffmpeg.ExportVideoFrame(videoFile, (uint)((skipSize * i) - offset));
}

Console.Clear();

ConsoleExtensions.WriteLineInColor("Compiling gif...", ConsoleColor.DarkCyan);
GifGenerator.FromFrames(frameFiles);

if(!args.Contains("--keep-frame-files"))
    foreach(var frameFile in frameFiles)
        File.Delete(frameFile);

Console.Clear();
ConsoleExtensions.WriteInColor("[SUCCESS] ", ConsoleColor.Green);
Console.WriteLine("Processing finished!");
