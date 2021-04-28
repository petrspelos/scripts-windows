using System;
using System.Diagnostics;
using System.IO;

namespace VideoPreviewMaker
{
    public abstract class ExternalApplication
    {
        protected abstract string QuietSwitch { get; }
        public abstract string ExecutableName { get; }

        protected Process _process;

        public ExternalApplication()
        {
            _process = new Process();
            _process.StartInfo.FileName = ExecutableName;
        }

        public bool Exists()
        {
            try
            {
                _process.StartInfo.Arguments = QuietSwitch;
                RunToCompletion();
            }
            catch(Exception e)
            {
                Console.WriteLine($"Error trying to run {ExecutableName}:\n{e.Message}");
                return false;
            }

            return true;
        }

        protected void RunToCompletion()
        {
            _process.Start();
            _process.WaitForExit();
        }

        protected string RunToCompletionAndGetOutput()
        {
            _process.StartInfo.RedirectStandardOutput = true;
            _process.Start();
            var output = _process.StandardOutput.ReadToEnd();
            _process.WaitForExit();
            return output;
        }
    }
}
