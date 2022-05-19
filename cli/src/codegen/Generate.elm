module Generate exposing (RoutePath, main, run)

{-| -}

import Elm
import Elm.Annotation
import Elm.Case
import Elm.Gen
import Gen.Basics
import Gen.Maybe
import Gen.Url.Parser


main : Program {} () ()
main =
    Platform.worker
        { init =
            \json ->
                ( ()
                , Elm.Gen.files
                    (files
                        [ [ "Home_" ]
                        , [ "SignIn" ]
                        , [ "Settings" ]
                        , [ "People", "Username_" ]
                        ]
                    )
                )
        , update = \msg model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


run : List RoutePath -> Cmd msg
run routePaths =
    Elm.Gen.files (files routePaths)


files : List RoutePath -> List Elm.File
files routePaths =
    [ mainElm routePaths
    , routeElm routePaths
    , notFoundElm
    ]



-- src/Pages/NotFound_.elm


notFoundElm : Elm.File
notFoundElm =
    Elm.file [ "Pages", "NotFound_" ]
        [ Elm.declaration "page"
            (Elm.apply
                (Elm.value
                    { importFrom = [ "Html" ]
                    , name = "text"
                    , annotation = Just annotations.htmlMsgGeneric
                    }
                )
                [ Elm.string "Page not found..."
                ]
            )
        ]


type alias RoutePath =
    List String



-- ROUTE.ELM


routeElm : List RoutePath -> Elm.File
routeElm routePaths =
    Elm.file [ "Route" ]
        [ Elm.unsafe "import Url.Parser exposing ((</>))"
        , routeType routePaths
            |> Elm.exposeWith
                { exposeConstructor = True
                , group = Nothing
                }
        , fromUrlFn
            |> Elm.expose
        , routeParserFn routePaths
        ]


routeType : List RoutePath -> Elm.Declaration
routeType paths =
    let
        toRouteVariant : RoutePath -> Elm.Variant
        toRouteVariant routePath =
            if isLastPieceDynamic routePath then
                Elm.variantWith (String.join "__" routePath)
                    [ Elm.Annotation.record [ ( "username", Elm.Annotation.string ) ]
                    ]

            else
                Elm.variant (String.join "__" routePath)
    in
    Elm.customType "Route"
        (List.map toRouteVariant paths ++ [ toRouteVariant [ "NotFound_" ] ])


{-|

    Url.Parser.parse routeParser url
        |> Maybe.withDefault NotFound_

-}
fromUrlFn : Elm.Declaration
fromUrlFn =
    Elm.declaration "fromUrl"
        (Elm.fn "url"
            (\url ->
                Gen.Maybe.withDefault
                    (Elm.value
                        { importFrom = []
                        , name = "NotFound_"
                        , annotation = Nothing
                        }
                    )
                    (Gen.Url.Parser.parse
                        (Elm.value { importFrom = [], name = "routeParser", annotation = Nothing })
                        url
                        |> Elm.withType
                            (Elm.Annotation.maybe
                                (Elm.Annotation.named [] "Route")
                            )
                    )
            )
        )


routeParserFn : List RoutePath -> Elm.Declaration
routeParserFn paths =
    let
        toUrlParser : RoutePath -> Elm.Expression
        toUrlParser routePath =
            if routePath == [ "Home_" ] then
                Gen.Url.Parser.map
                    (Elm.value
                        { importFrom = []
                        , name = "Home_"
                        , annotation = Nothing
                        }
                    )
                    Gen.Url.Parser.top

            else
                Gen.Url.Parser.map
                    (toRouteConstructor routePath)
                    (routePath
                        |> List.map toRouteSegmentParser
                        |> List.foldl joinWithUrlSlash Nothing
                        |> Maybe.withDefault Gen.Url.Parser.top
                    )

        toRouteSegmentParser : String -> Elm.Expression
        toRouteSegmentParser pathSegment =
            if String.endsWith "_" pathSegment then
                Gen.Url.Parser.string

            else
                Gen.Url.Parser.s (fromPascalCaseToKebabCase pathSegment)

        fromPascalCaseToKebabCase : String -> String
        fromPascalCaseToKebabCase str =
            str
                |> String.toList
                |> List.concatMap
                    (\char ->
                        if Char.isUpper char then
                            [ '-', Char.toLower char ]

                        else
                            [ char ]
                    )
                |> String.fromList
                |> String.dropLeft 1

        joinWithUrlSlash : Elm.Expression -> Maybe Elm.Expression -> Maybe Elm.Expression
        joinWithUrlSlash expr1 maybeExpr =
            case maybeExpr of
                Nothing ->
                    Just expr1

                Just expr2 ->
                    Just (Elm.slash expr2 expr1)

        fromPascalCaseToCamelCase : String -> String
        fromPascalCaseToCamelCase str =
            String.toLower (String.left 1 str) ++ String.dropLeft 1 str

        toRouteConstructor : RoutePath -> Elm.Expression
        toRouteConstructor routePath =
            let
                dynamicValues : List String
                dynamicValues =
                    routePath
                        |> List.filter (String.endsWith "_")

                numberOfDynamicValues : Int
                numberOfDynamicValues =
                    List.length dynamicValues
            in
            if numberOfDynamicValues > 0 then
                Elm.function
                    (( "param", Nothing )
                        |> List.repeat numberOfDynamicValues
                        |> List.indexedMap
                            (\i ( str, maybe ) ->
                                ( str ++ String.fromInt (i + 1), maybe )
                            )
                    )
                    (\exprs ->
                        Elm.apply
                            (Elm.value
                                { importFrom = []
                                , name = String.join "__" routePath
                                , annotation = Nothing
                                }
                            )
                            [ Elm.record
                                (List.map2
                                    (\nameWithUnderscore expr ->
                                        Elm.field
                                            (fromPascalCaseToCamelCase (String.dropRight 1 nameWithUnderscore))
                                            expr
                                    )
                                    dynamicValues
                                    exprs
                                )
                            ]
                    )

            else
                Elm.value
                    { importFrom = []
                    , name = String.join "__" routePath
                    , annotation = Nothing
                    }
    in
    Elm.declaration "routeParser"
        (Elm.apply
            (Elm.value
                { importFrom = [ "Url", "Parser" ]
                , name = "oneOf"
                , annotation =
                    Nothing
                }
            )
            [ Elm.list
                (List.map
                    toUrlParser
                    paths
                )
            ]
            |> Elm.withType
                (Gen.Url.Parser.annotation_.parser
                    (Elm.Annotation.function
                        [ Elm.Annotation.named [] "Route"
                        ]
                        (Elm.Annotation.var "x")
                    )
                    (Elm.Annotation.var "x")
                )
        )



-- MAIN.ELM


mainElm : List RoutePath -> Elm.File
mainElm routePaths =
    Elm.file [ "Main" ]
        [ flagsAlias
        , Elm.expose mainFn
        , Elm.comment "INIT"
        , modelTypeAlias
        , initFn
        , Elm.comment "UPDATE"
        , msgType
        , updateFn
        , subscriptionsFn
        , Elm.comment "VIEW"
        , viewFn
        , viewPageFn routePaths
        ]


flagsAlias : Elm.Declaration
flagsAlias =
    Elm.alias "Flags"
        (Elm.Annotation.named [ "Json.Decode" ] "Value")


mainFn : Elm.Declaration
mainFn =
    let
        programTypeAnnotation : Elm.Annotation.Annotation
        programTypeAnnotation =
            Elm.Annotation.namedWith []
                "Program"
                [ annotations.flags
                , annotations.model
                , annotations.msg
                ]
    in
    Elm.declaration "main"
        (Elm.apply
            (Elm.value
                { importFrom = [ "Browser" ]
                , name = "application"
                , annotation = Nothing
                }
            )
            [ Elm.record
                [ Elm.field "init" (ref "init")
                , Elm.field "update" (ref "update")
                , Elm.field "view" (ref "view")
                , Elm.field "subscriptions" (ref "subscriptions")
                , Elm.field "onUrlChange" (ref "UrlChanged")
                , Elm.field "onUrlRequest" (ref "UrlRequested")
                ]
            ]
            |> Elm.withType programTypeAnnotation
        )


modelTypeAlias : Elm.Declaration
modelTypeAlias =
    Elm.alias "Model"
        (Elm.Annotation.record
            [ ( "flags", Elm.Annotation.named [] "Flags" )
            , ( "key", annotations.browserKey )
            , ( "url", annotations.url )
            ]
        )


initFn : Elm.Declaration
initFn =
    Elm.unsafe """
init : Flags -> Url.Url -> Browser.Navigation.Key -> (Model, Cmd Msg)
init flags url key =
    ( { flags = flags
      , url = url
      , key = key
      }
    , Cmd.none
    )
"""


msgType : Elm.Declaration
msgType =
    Elm.customType "Msg"
        [ Elm.variantWith "UrlRequested" [ annotations.urlRequest ]
        , Elm.variantWith "UrlChanged" [ annotations.url ]
        ]


updateFn : Elm.Declaration
updateFn =
    -- Elm.declaration "update"
    --     (Elm.fn2 "msg"
    --         "model"
    --         (\msg model ->
    -- Elm.Case.custom msg
    --     [ Elm.Case.branch1 []
    --         "UrlChanged"
    --         (\url ->
    --             Elm.tuple
    --                 (Elm.updateRecord model
    --                     [ Elm.field "url" url
    --                     ]
    --                 )
    --                 values.cmdNone
    --         )
    --     ,
    --     -- Elm.Case.branch1 []
    --     --     "UrlRequested"
    --     --     (\url ->
    --     --         Elm.tuple
    --     --             model
    --     --             (Elm.apply
    --     --                 (Elm.value
    --     --                     { importFrom = [ "Browser", "Navigation" ]
    --     --                     , name = "pushUrl"
    --     --                     , annotation = Nothing
    --     --                     }
    --     --                 )
    --     --                 [ model |> Elm.get "key"
    --     --                 , url
    --     --                 ]
    --     --             )
    --     --     )
    --     ]
    --     )
    --     |> Elm.withType
    --         (Elm.Annotation.function
    --             [ annotations.msg
    --             , annotations.model
    --             ]
    --             (Elm.Annotation.tuple annotations.model annotations.cmdMsg)
    --         )
    -- )
    Elm.unsafe """
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested (Browser.Internal url) ->
            ( model
            , Browser.Navigation.pushUrl model.key (Url.toString url)
            )

        UrlRequested (Browser.External url) ->
            ( model
            , Browser.Navigation.load url
            )

        UrlChanged url ->
            ( { model | url = url }, Cmd.none )
"""


subscriptionsFn : Elm.Declaration
subscriptionsFn =
    Elm.declaration "subscriptions"
        (Elm.fn "model"
            (\model -> values.subNone)
        )


viewFn : Elm.Declaration
viewFn =
    Elm.declaration "view"
        (Elm.fn "model"
            (\model ->
                Elm.record
                    [ Elm.field "title" (Elm.string "App")
                    , Elm.field "body"
                        (Elm.list
                            [ Elm.apply
                                (Elm.value
                                    { importFrom = []
                                    , name = "viewPage"
                                    , annotation = Nothing
                                    }
                                )
                                [ model
                                ]
                            ]
                        )
                    ]
            )
            |> Elm.withType (Elm.Annotation.function [ annotations.model ] annotations.documentMsg)
        )


viewPageFn : List (List String) -> Elm.Declaration
viewPageFn routes =
    let
        branches : List Elm.Case.Branch
        branches =
            List.map toBranch routes ++ [ toBranch [ "NotFound_" ] ]

        {-
           Route.Home_ ->
               Pages.Home_.page
        -}
        toBranch : List String -> Elm.Case.Branch
        toBranch routePath =
            if isLastPieceDynamic routePath then
                Elm.Case.branch1 [ "Route" ]
                    (String.join "__" routePath)
                    (\params ->
                        Elm.apply
                            (Elm.value
                                { importFrom = "Pages" :: routePath
                                , name = "page"
                                , annotation = Nothing
                                }
                            )
                            [ params ]
                    )

            else
                Elm.Case.branch0 [ "Route" ]
                    (String.join "__" routePath)
                    (Elm.value
                        { importFrom = "Pages" :: routePath
                        , name = "page"
                        , annotation = Just annotations.htmlMsg
                        }
                    )

        routeFromUrl : Elm.Expression -> Elm.Expression
        routeFromUrl model =
            Elm.apply
                (Elm.value
                    { importFrom = [ "Route" ]
                    , name = "fromUrl"
                    , annotation = Just annotations.route
                    }
                )
                [ model |> Elm.get "url" ]
    in
    Elm.declaration "viewPage"
        (Elm.fn "model"
            (\model ->
                Elm.Case.custom (routeFromUrl model) branches
                    |> Elm.withType annotations.htmlMsg
            )
            |> Elm.withType (Elm.Annotation.function [ annotations.model ] annotations.htmlMsg)
        )


isLastPieceDynamic : List String -> Bool
isLastPieceDynamic pieces =
    case List.drop (List.length pieces - 1) pieces of
        [] ->
            False

        item :: _ ->
            if List.member item [ "Home_", "NotFound_" ] then
                False

            else
                String.endsWith "_" item



-- REUSED


annotations =
    { flags = Elm.Annotation.named [] "Flags"
    , model = Elm.Annotation.named [] "Model"
    , msg = Elm.Annotation.named [] "Msg"
    , browserKey = Elm.Annotation.named [ "Browser.Navigation" ] "Key"
    , urlRequest = Elm.Annotation.named [ "Browser" ] "UrlRequest"
    , documentMsg = Elm.Annotation.namedWith [ "Browser" ] "Document" [ Elm.Annotation.named [] "Msg" ]
    , htmlMsg = Elm.Annotation.namedWith [ "Html" ] "Html" [ Elm.Annotation.named [] "Msg" ]
    , htmlMsgGeneric = Elm.Annotation.namedWith [ "Html" ] "Html" [ Elm.Annotation.var "msg" ]
    , url = Elm.Annotation.named [ "Url" ] "Url"
    , subMsg =
        Elm.Annotation.namedWith []
            "Sub"
            [ Elm.Annotation.named [] "Msg"
            ]
    , cmdMsg =
        Elm.Annotation.namedWith []
            "Cmd"
            [ Elm.Annotation.named [] "Msg"
            ]
    , route =
        Elm.Annotation.named [ "Route" ] "Route"
    }


values =
    { cmdNone =
        Elm.value
            { importFrom = []
            , name = "Cmd.none"
            , annotation = Just annotations.cmdMsg
            }
    , subNone =
        Elm.value
            { importFrom = []
            , name = "Sub.none"
            , annotation = Just annotations.subMsg
            }
    }



-- HELPERS


ref : String -> Elm.Expression
ref name =
    Elm.value { importFrom = [], name = name, annotation = Nothing }