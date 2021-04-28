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

Console.WriteLine("Getting the video's frames count...");

var frames = ffprobe.GetVideoFramesCount(videoFile);

Console.Clear();
Console.WriteLine($"The video in question has {frames} frame(s).");
Console.WriteLine("Picking frames for preview...");

var skipSize = (frames - 1) / 4;
var offset = skipSize / 2;

var frameFiles = new string[4];

for(var i = 1; i < frameFiles.Length + 1; i++)
    frameFiles[i - 1] = ffmpeg.ExportVideoFrame(videoFile, (uint)((skipSize * i) - offset));

GifGenerator.FromFrames(frameFiles);

if(!args.Contains("--keep-frame-files"))
    foreach(var frameFile in frameFiles)
        File.Delete(frameFile);

Console.WriteLine("Processing finished!");
