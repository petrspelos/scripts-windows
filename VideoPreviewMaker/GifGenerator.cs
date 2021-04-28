using System;
using System.Collections.Generic;
using System.IO;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats;
using SixLabors.ImageSharp.Formats.Gif;

namespace VideoPreviewMaker
{
    public class GifGenerator
    {
        public static void FromFrames(params string[] framePaths)
        {
            var images = new List<Image>();

            foreach(var frame in framePaths)
            {
                if(!File.Exists(frame))
                    throw new Exception($"Could not find frame file '{frame}'.");

                images.Add(Image.Load(frame, out IImageFormat _));
            }

            for(var i = 1; i < images.Count; i++)
            {
                images[0].Frames.AddFrame(images[i].Frames[0]);
            }

            foreach(var frame in images[0].Frames)
                frame.Metadata.GetGifMetadata().FrameDelay = 100;

            images[0].Metadata.GetFormatMetadata(GifFormat.Instance).ColorTableMode = GifColorTableMode.Local;

            images[0].SaveAsGif("preview.gif");

            foreach(var image in images)
                image.Dispose();
        }
    }
}
