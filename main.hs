{-# LANGUAGE OverloadedStrings #-}

import Control.Concurrent
import Control.Exception
import Control.Monad
import Data.ByteString.Char8 (pack, unpack)
import Data.HashMap.Strict (HashMap)
import qualified Data.HashMap.Strict as HashMap
import Data.Text (Text)
import qualified Data.Text as Text
import qualified Data.Text.IO as TextIO
import Data.Aeson (encode, decode, object, (.=))
import Data.Aeson.Types (FromJSON, ToJSON)
import Network.Socket
import Network.Socket.ByteString (sendAll, recv)
import Crypto.Hash (SHA256, hash)
import Data.Maybe (fromMaybe)

-- Data type for messages
data Message = Message { content :: Text } deriving (Show)

instance ToJSON Message where
    toJSON (Message c) = object ["content" .= c]

instance FromJSON Message where
    parseJSON = withObject "Message" \( \v -> Message <\)> v .: "content"

-- Simple Sentiment Analysis (placeholder logic)
analyzeSentiment :: Text -> String
analyzeSentiment text
    | Text.isInfixOf "good" text  = "Positive"
    | Text.isInfixOf "bad" text   = "Negative"
    | otherwise                    = "Neutral"

-- Function to hash message content
hashMessage :: Message -> String
hashMessage msg = show . hash . pack $ Text.unpack (content msg)

-- Function to handle client connections
handleClient :: Socket -> IO ()
handleClient sock = do
    msg <- recv sock 1024
    case decode msg of
        Just message -> do
            let response = analyzeSentiment (content message)
            TextIO.putStrLn $ "Received message: " <> content message
            TextIO.putStrLn $ "Sentiment: " <> Text.pack response
            sendAll sock (encode (Message (Text.pack response)))
        Nothing -> putStrLn "Failed to decode message."
    close sock

-- Server setup
main :: IO ()
main = do
    addrInfo <- getAddrInfo (Just defaultHints) (Just "localhost") (Just "8080")
    let serverAddr = head addrInfo

    sock <- socket (addrFamily serverAddr) Stream defaultProtocol
    bind sock (addrAddress serverAddr)
    listen sock 5
    putStrLn "Server listening on port 8080..."

    forever $ do
        (clientSock, _) <- accept sock
        forkIO $ handleClient clientSock `catch` handleException

-- Error handling
handleException :: SomeException -> IO ()
handleException e = putStrLn $ "Error: " ++ show e

-- Secure the data
secureData :: String -> String
secureData input = show (hash (pack input) :: SHA256)

-- Leo specific threat detection patterns (placeholder)
detectThreats :: Text -> Bool
detectThreats text = any (`Text.isInfixOf` text) ["attack", "breach", "malware"]

-- Example of using detection function
checkThreats :: Text -> IO ()
checkThreats text = do
    if detectThreats text
        then putStrLn "Threat detected!"
        else putStrLn "No threat detected."
