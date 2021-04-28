using System;
using System.IO;

namespace VideoPreviewMaker
{
    public class Ffmpeg : ExternalApplication
    {
        public Ffmpeg() : base()
        {
        }

        public override string ExecutableName => "C:/tools/ffmpeg.exe";

        public string ExportVideoFrame(string filePath, uint frame)
        {
            if(!File.Exists(filePath))
                throw new FileNotFoundException($"The file '{filePath}' was not found.");

            var frameFile = $"frame-{frame}.png";

            File.Delete(frameFile);

            _process.StartInfo.Arguments = $"-i \"{filePath}\" -vf \"select=eq(n\\,{frame})\" -vframes 1 {frameFile}";

            RunToCompletion();
            return frameFile;
        }
    }
}
