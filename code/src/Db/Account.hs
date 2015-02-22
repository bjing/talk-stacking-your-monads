{-# LANGUAGE Arrows                #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NoImplicitPrelude     #-}
{-# LANGUAGE TemplateHaskell       #-}
module Db.Account
  ( Account'(Account)
  , NewAccount
  , Account
  , allAccounts
  , accountQuery
  , insertAccount
  , getAccount
  , accountId
  , accountName
  , accountNumber
  , accountType
  ) where

import BasePrelude hiding (optional)

import Control.Lens
import Control.Monad.Except       (MonadError)
import Control.Monad.Reader       (MonadReader)
import Control.Monad.Trans        (MonadIO)
import Data.Profunctor.Product.TH (makeAdaptorAndInstance)
import Data.Text                  (Text)
import Opaleye

import Db.Internal

data Account' a b c d = Account
  { _accountId     :: a
  , _accountType   :: b
  , _accountNumber :: c
  , _accountName   :: d
  } deriving (Eq,Show)
makeLenses ''Account'

type Account = Account' Int Text Int Text
type AccountColumn = Account'
  (Column PGInt4)
  (Column PGText)
  (Column PGInt4)
  (Column PGText)

makeAdaptorAndInstance "pAccount" ''Account'

type NewAccount = Account' (Maybe Int) Text Int Text

type NewAccountColumn = Account'
  (Maybe (Column PGInt4)) (Column PGText) (Column PGInt4) (Column PGText)

accountTable :: Table NewAccountColumn AccountColumn
accountTable = Table "account" $ pAccount Account
  { _accountId     = optional "id"
  , _accountType   = required "type"
  , _accountNumber = required "number"
  , _accountName   = required "name"
  }

accountQuery :: Query AccountColumn
accountQuery = queryTable accountTable

allAccounts :: Db [Account]
allAccounts = liftQuery accountQuery

getAccount :: Int -> Db (Maybe Account)
getAccount i = liftQueryFirst $ proc () -> do
  a <- accountQuery -< ()
  restrict -< a^.accountId .== pgInt4 i
  returnA -< a

insertAccount
  :: ( MonadReader DbEnv m
    , MonadError DbError m
    , Applicative m
    , MonadIO m
    )
  => NewAccount
  -> m [Int]
insertAccount =
  liftInsertReturning accountTable (view accountId) . packNew

packNew :: NewAccount -> NewAccountColumn
packNew = pAccount Account
  { _accountId     = fmap pgInt4
  , _accountType   = pgStrictText
  , _accountNumber = pgInt4
  , _accountName   = pgStrictText
  }
