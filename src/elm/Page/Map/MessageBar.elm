module Page.Map.MessageBar exposing (view)

import API.API as API
import Html exposing (..)
import Http
import Model.I18n as I18n exposing (Language)
import Model.Information exposing (Information(..))
import View.MessageBar as MessageBar


view : Language -> Information -> Html msg
view lang e =
    case e of
        NoInformation ->
            MessageBar.none

        Success message ->
            MessageBar.success message

        DisplayLink objectId ->
            MessageBar.success (I18n.displayingLinkToObject lang objectId)

        PublishInProgress floorName ->
            MessageBar.default (I18n.publishingInProgressPreaseWaitForSeconds lang floorName)

        PublishedFloor floorName ->
            MessageBar.success (I18n.successfullyPublished lang floorName)

        APIError e ->
            MessageBar.error (describeAPIError lang e)

        FileError e ->
            MessageBar.error (I18n.unexpectedFileError lang ++ ": " ++ toString e)

        HtmlError e ->
            MessageBar.error (I18n.unexpectedHtmlError lang ++ ": " ++ toString e)

        PasteError s ->
            MessageBar.error s


describeAPIError : Language -> API.Error -> String
describeAPIError lang e =
    case e of
        Http.BadUrl url ->
            I18n.unexpectedBadUrl lang ++ ": " ++ url

        Http.Timeout ->
            I18n.timeout lang

        Http.NetworkError ->
            I18n.networkErrorDetectedPleaseRefreshAndTryAgain lang

        Http.BadStatus res ->
            if res.status.code == 409 then
                I18n.conflictSomeoneHasAlreadyChangedPleaseRefreshAndTryAgain lang
            else
                I18n.unexpectedBadStatus lang ++ ": " ++ toString res.status.code ++ " " ++ res.status.message

        Http.BadPayload str res ->
            I18n.unexpectedPayload lang ++ ": " ++ str



--
