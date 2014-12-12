module StarExec.PersistTypes where

import Import
import Model
import qualified Data.Csv as CSV
import qualified Data.Text as T
import qualified Data.Text.Read as TRead
import Data.Text.Encoding
import GHC.Generics
import Control.Applicative
import StarExec.Types

import qualified StarExec.Complexity as C

instance CSV.FromNamedRecord JobResultInfo where
  parseNamedRecord r =
    JobResultInfo (-1) Nothing
                  <$> r CSV..: "pair id"
                  <*> r CSV..: "benchmark"
                  <*> r CSV..: "benchmark id"
                  <*> r CSV..: "solver"
                  <*> r CSV..: "solver id"
                  <*> r CSV..: "configuration"
                  <*> r CSV..: "configuration id"
                  <*> r CSV..: "status"
                  <*> r CSV..: "cpu time"
                  <*> r CSV..: "wallclock time"
                  <*> r CSV..: "result"

instance CSV.FromField SolverResult where
    parseField result = parseResult s
        where
            s = T.toLower $ decodeUtf8 result
            parseResult r
                | r == "no"         = pure NO
                | r == "maybe"      = pure MAYBE
                | r == "certified"  = pure CERTIFIED
                | r == "error"      = pure ERROR
                | r == "yes"        = pure $ YES Nothing
                | otherwise = case readsPrec 0 $ T.unpack $ decodeUtf8 result of
                    [ ( C.Bounds { C.upper = C.Poly (Just deg) } , "" ) ]
                        -> pure $ YES $ Just deg
                    _ -> pure OTHER
{-
                | otherwise         =
                    if "yes" `T.isPrefixOf` r
                      then pure $ YES $ getPolynomial $ T.drop 3 r
                      else pure OTHER
            getPolynomial "" = Nothing
            getPolynomial r = -- "(?,n^x)"
              let iText = T.dropWhile (/='^') r -- "^x)"
                  tLength = T.length iText
              in if tLength >= 3
                    then let x = T.drop 1 iText
                         in case TRead.decimal x of
                              Right (i,_) -> Just i
                              Left _ -> Nothing
                    else Nothing
-}

instance CSV.FromField JobResultStatus where
    parseField result = parseResult s
        where
            s = T.toLower $ decodeUtf8 result
            parseResult r
                | r == "running"             = pure JobResultRunning
                | r == "enqueued"            = pure JobResultEnqueued
                | "pending" `T.isPrefixOf` r = pure JobResultPending
                | otherwise                  = pure JobResultComplete
                -- | otherwise       = pure $ JobResultOther s

{-
-}
data PrimInfo = PrimJobInfo JobInfo
                | PrimSolverInfo SolverInfo
                | PrimBenchmarkInfo BenchmarkInfo
                -- | PrimUserInfo UserInfo
                | PrimSpaceInfo SpaceInfo
  deriving (Show)

toJobInfo :: PrimInfo -> JobInfo
toJobInfo (PrimJobInfo info) = info

toJobInfos :: [PrimInfo] -> [JobInfo]
toJobInfos = map toJobInfo

toSolverInfo :: PrimInfo -> SolverInfo
toSolverInfo (PrimSolverInfo info) = info

toSolverInfos :: [PrimInfo] -> [SolverInfo]
toSolverInfos = map toSolverInfo

toBenchmarkInfo :: PrimInfo -> BenchmarkInfo
toBenchmarkInfo (PrimBenchmarkInfo info) = info

toBenchmarkInfos :: [PrimInfo] -> [BenchmarkInfo]
toBenchmarkInfos = map toBenchmarkInfo

--toUserInfo :: PrimInfo -> UserInfo
--toUserInfo (PrimUserInfo info) = info

--toUserInfos :: [PrimInfo] -> [UserInfo]
--toUserInfos = map toUserInfo

toSpaceInfo :: PrimInfo -> SpaceInfo
toSpaceInfo (PrimSpaceInfo info) = info

toSpaceInfos :: [PrimInfo] -> [SpaceInfo]
toSpaceInfos = map toSpaceInfo

primInfoId :: PrimInfo -> Int
primInfoId primInfo =
  case primInfo of
    PrimJobInfo info       -> jobInfoStarExecId info
    PrimBenchmarkInfo info -> benchmarkInfoStarExecId info
    PrimSolverInfo info    -> solverInfoStarExecId info
    PrimSpaceInfo info     -> spaceId info
    --PrimUserInfo info      -> userId info

primInfoName :: PrimInfo -> Text
primInfoName primInfo =
  case primInfo of
    PrimJobInfo info       -> jobInfoName info
    PrimBenchmarkInfo info -> benchmarkInfoName info
    PrimSolverInfo info    -> solverInfoName info
    PrimSpaceInfo info     -> spaceName info
    --PrimUserInfo info      -> userName info

data QueryIntermediateResult =
  QIRJobInfo (Maybe JobInfo)
  | QIRSolverInfo (Maybe SolverInfo)
  | QIRBenchmarkInfo (Maybe BenchmarkInfo)
  | QIRJobPairInfo (Maybe JobPairInfo)
  | QIRJobResults [JobResultInfo]
  deriving (Show)