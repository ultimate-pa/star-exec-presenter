module FCA.StarExec where

import FCA.Utils
import Import
import Presenter.Model.Entities()
import Presenter.PersistHelper

import Data.Maybe
import Data.List hiding (isPrefixOf, stripPrefix)
import Data.Text (append, pack, isPrefixOf, stripPrefix)


data Attribute =
  AJobResultInfoSolver Text
   | AJobResultInfoConfiguration Text
   | ASlowCpuTime Bool
   | ASolverResult SolverResult
  deriving (Eq, Ord, Show)


-- get context of job results by given JobID
jobResultsContext:: JobID -> Handler (Context JobPairID Attribute)
jobResultsContext jid = do
  jobResults <- getPersistJobResults jid
  return $ contextFromList . collectData $ getStarExecResults jobResults

-- all job pairs with a response time greater 10 seconds is slow
slowCpuTimeLimit :: (Num Double, Ord Double) => Double
slowCpuTimeLimit = 10

-- create relation of JobPairID and declared attributes of given data
collectData :: [JobResultInfo] -> [(JobPairID, [Attribute])]
collectData results = zip (map (StarExecPairID . jobResultInfoPairId) results) (getAttributeCollection results)

-- create collection of selected attributes of given data
getAttributeCollection :: [JobResultInfo] -> [[Attribute]]
getAttributeCollection jobResults = do
  let jobResultInfoSolvers = map jobResultInfoSolver jobResults
  let jobResultInfoConfigurations = map jobResultInfoConfiguration jobResults
  -- let jobResultInfoBenchmarkIds = map (jobResultInfoBenchmarkId) jobResults
  let cpuTimeEvaluations = evaluateCpuTime jobResults
  let jobResultInfoResults = map jobResultInfoResult jobResults
  zipWith4 (\a b c d -> [AJobResultInfoSolver a, AJobResultInfoConfiguration b, ASlowCpuTime c, ASolverResult d])
    jobResultInfoSolvers jobResultInfoConfigurations cpuTimeEvaluations jobResultInfoResults

-- evaluate whether time are slow or not
evaluateCpuTime :: [JobResultInfo] -> [Bool]
evaluateCpuTime = map ((> slowCpuTimeLimit). jobResultInfoCpuTime)

-- proper names for attributes in template
properAttrName :: Attribute -> Text
properAttrName at = case at of
 (AJobResultInfoSolver name)          -> append "Solver name " name
 (AJobResultInfoConfiguration config) -> append "Solver config " config
 (ASlowCpuTime fast)    -> case fast of
                            False         -> "CPU time <= 10s"
                            True          -> "CPU time > 10s"
 (ASolverResult result) -> case result of
                            YES           -> "Result YES"
                            NO            -> "Result NO"
                            MAYBE         -> "Result MAYBE"
                            (BOUNDS b)    -> append "Result BOUNDS " $ pack $ show b
                            CERTIFIED     -> "Result CERTIFIED"
                            ERROR         -> "Result ERROR"
                            (OTHER text)  -> append "Result OTHER " text

stripAttributePrefixes :: Text -> Text
stripAttributePrefixes at
  | isPrefixOf "Result " at = fromJust $ stripPrefix "Result " at
  | isPrefixOf "Solver config " at = fromJust $ stripPrefix "Solver config " at
  | isPrefixOf "Solver name " at = fromJust $ stripPrefix "Solver name " at
  | isPrefixOf "CPU " at = fromJust $ stripPrefix "CPU " at
  | otherwise = at
