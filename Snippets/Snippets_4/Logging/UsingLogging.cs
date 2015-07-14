﻿namespace Snippets4.Logging
{
    using NServiceBus.Logging;

    #region UsingLogging

    public class ClassUsingLogging
    {
        public void SomeMethod()
        {
            //your code
            Logger.Debug("Something interesting happened.");
        }

        static ILog Logger = LogManager.GetLogger(typeof(ClassUsingLogging));
    }

    #endregion

}