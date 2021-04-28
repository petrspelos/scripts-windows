using System;

namespace VideoPreviewMaker
{
    public static class ConsoleExtensions
    {
        private const string EmptyTile = "░";
        private const string FilledTile = "█";

        public static void Progress(int width, int current, int max) => Progress(width, (float)current / max);

        public static void Progress(int width, float percentage)
        {
            if(percentage > 1.0f || percentage < 0.0f)
                throw new ArgumentException($"{nameof(percentage)} must be between 0.0 and 1.0");

            int progressEnd = width;
            int currentValue = (int)(percentage * width);

            Progress(progressEnd, currentValue);
        }

        public static void Progress(int width, int current)
        {
            WriteInColor("[ ", ConsoleColor.Gray);

            for(var i = 1; i <= width; i++)
            {
                if(i <= current)
                    WriteInColor(FilledTile, ConsoleColor.Green);
                else
                    WriteInColor(EmptyTile, ConsoleColor.Gray);
            }

            WriteLineInColor(" ]", ConsoleColor.Gray);
        }

        public static void WriteLineInColor(string text, ConsoleColor color = ConsoleColor.White) => WriteInColor($"{text}\n", color);

        public static void WriteInColor(string text, ConsoleColor color = ConsoleColor.White)
        {
            Console.ForegroundColor = color;
            Console.Write(text);
            Console.ResetColor();
        }
    }
}
