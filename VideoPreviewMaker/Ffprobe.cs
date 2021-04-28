using System;
using System.IO;

namespace VideoPreviewMaker
{
    public class Ffprobe : ExternalApplication
    {
        public Ffprobe() : base()
        {
        }

        public override string ExecutableName => "C:/tools/ffprobe.exe";

        protected override string QuietSwitch => "";

        public uint GetVideoFramesCount(string filePath)
        {
            if(!File.Exists(filePath))
                throw new FileNotFoundException($"The file '{filePath}' was not found.");

            _process.StartInfo.Arguments = $"{QuietSwitch} -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 \"{filePath}\"";
            var output = RunToCompletionAndGetOutput();

            var success = uint.TryParse(output, out var result);

            if(!success)
                throw new Exception($"Failed to parse frame count. ffprobe output: '{output}'");

            return result;
        }
    }
}
