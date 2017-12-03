using System;
using System.Reflection;

namespace ConsoleApp1
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine($"Hello from {Assembly.GetExecutingAssembly().GetName().Name}");
        }
    }
}
