{-# LANGUAGE OverloadedStrings #-}

import Hakyll

main :: IO ()
main = hakyll $ do
  match "stylesheets/site.scss" $ do
    route $ setExtension "css"
    compile compressScssCompiler

  match "images/*" $ route idRoute >> compile copyFileCompiler    
  match "static/*" $ route idRoute >> compile copyFileCompiler

  match "posts/*" $ version "titleLine" $ do
    route $ gsubRoute "pages/" (const "") `composeRoutes` setExtension "html"
    compile $ pandocCompiler
        >>= saveSnapshot "content"    
        >>= relativizeUrls

  match "posts/*" $ do
    route $ gsubRoute "pages/" (const "") `composeRoutes` setExtension "html"
    compile $ do     
      postList <- loadAll ("posts/*" .&&. hasVersion "titleLine")    
      let postCtz = listField "posts" postCtx (return postList) `mappend`
                    dateField "date" "%Y-%m-%d" `mappend` defaultContext

      pandocCompiler
        >>= saveSnapshot "content"
        >>= loadAndApplyTemplate "templates/default.html" postCtz
        >>= relativizeUrls

  match "index.md" $ do
    route $ setExtension "html"
    compile $ do
      posts <- loadAll ("posts/*" .&&. hasVersion "titleLine") >>= recentFirst
      let indexCtx =
            listField "posts" postCtx (return posts) `mappend`
            constField "title" "Home"                `mappend`
            defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= renderPandoc
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "templates/default.html" $ compile templateCompiler
  match "templates/navbar.html" $ compile templateCompiler

  create ["atom.xml"] $ do
    route idRoute
    compile $ loadAllSnapshots ("posts/*" .&&. hasVersion "titleLine") "content"
        >>= fmap (take 10) . recentFirst    
        >>= renderAtom feedConfiguration feedCtx
        where
          feedConfiguration = FeedConfiguration
            { feedTitle       = "luketebbs.com"
            , feedDescription = ""
            , feedAuthorName  = "Luke Tebbs"
            , feedAuthorEmail = "luke@luketebbs.com"
            , feedRoot        = "http://www.luketebbs.com"
            }
          feedCtx = bodyField "description" `mappend` postCtx

postCtx :: Context String
postCtx = dateField "date" "%Y-%m-%d" `mappend` defaultContext

-- | Create a SCSS compiler that transpiles the SCSS to CSS and
-- minifies it (relying on the external 'sass' tool)
compressScssCompiler :: Compiler (Item String)
compressScssCompiler = fmap (fmap compressCss) $
  getResourceString
  >>= withItemBody (unixFilter "sass" [ "-s"
                                        , "--scss"
                                        , "--style", "compressed"
                                        , "--load-path", "stylesheets"
                                        ])
