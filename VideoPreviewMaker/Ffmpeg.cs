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

        protected override string QuietSwitch => "";

        public string ExportVideoFrame(string filePath, uint frame)
        {
            if(!File.Exists(filePath))
                throw new FileNotFoundException($"The file '{filePath}' was not found.");

            var frameFile = $"{string.Format(Configuration.FrameFileNameFormat, frame)}.png";

            File.Delete(frameFile);

            _process.StartInfo.Arguments = $"{QuietSwitch}-i \"{filePath}\" -vf \"select=eq(n\\,{frame})\" -vframes 1 {frameFile} -nostdin -loglevel quiet";
            _process.StartInfo.RedirectStandardOutput = false;

            RunToCompletion();
            return frameFile;
        }
    }
}
