// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

var gCompanyFilter = null;
var gGroupID = null;
var gMoreInfoName=null;
var gMoreInfoElement=null;
var gIgnoreElement = null;
var gIgnoredName = null;
var gShowMoreElementToRemove = null;
var gConnectionsStrength = {};
var gConnectedSalesForce = {
    contactsId: []
};

$(function() {

// Commented due to bug#324
//    if(showOfunnelHelp) {
//        $.colorbox({
//            html: $('#welcome-to-ofunnel').html(),
//            overlayClose: false
//        });
//
//        $('a.close-welcome-popup').click(function() {
//            $.colorbox.close()
//        });
//    }

    if(typeof trackLoginEvent != "undefined" && trackLoginEvent && typeof hootsuiteEnabled == "undefined")
        payBoradLoginEvent();

    if(typeof trackAlertEvent != "undefined" && trackAlertEvent && typeof hootsuiteEnabled == "undefined")
        payBoardNewAlertEvent();

    $(".groupinfo").mouseenter(function(){
        adjustTooltip();
        $(".tooltip-box").show();
    });

    $(".groupinfo").mouseleave(function(){
        $(".tooltip-box").hide();
    });

    $(".groupinfo2").mouseenter(function(){
        adjustTooltip2();
        $(".tooltip-box").show();
    });

    $(".groupinfo2").mouseleave(function(){
        $(".tooltip-box").hide();
    });

    $(".requested-info").mouseenter(function(){
        $(".tooltip-box").show();
    });

    $(".requested-info").mouseleave(function(){
        $(".tooltip-box").hide();
    });

    $(".colorbox-popup").colorbox();

    $(".mygroups-dbox").mouseover(function(){
        $(".g-dropdown").show();
        $(".mygroups-dbox .arrow").addClass("arrow-hover");
    });

    $(".mygroups-dbox").mouseout(function(){
        $(".g-dropdown").hide();
        $(".mygroups-dbox .arrow").removeClass("arrow-hover");
    });

    $('span.multiline-ellipsis').dotdotdot({
        height : 40
    });

    $('.openrequests,.no-result-open-request').click(function(){
        $('.autocomplete-box').hide();
        $.colorbox({
            html: $('#open-request').html(),
            overlayClose: false
        });
        requestAutoComplete();
        return false;
    });

    $('a#add-member-to-group').click(function() {
        $.colorbox({
            html: $('#add-member').html(),
            overlayClose: false,
            width: "630px"
        });
        searchPeopleForQuery();
        return false;
    });

    $('a#add-admin').click(function() {
        $.colorbox({
            html: $('#add-admin-popup').html(),
            overlayClose: false
//            height: "380px"
        });
        return false;
    });

    $('a#import-from-csv').click(function() {
        $.colorbox({
            html: $('#import-from-csv-popup').html(),
            overlayClose: false
        });
        return false;
    });

    $('a#alert-add-target-account-list').click(function() {
        $.colorbox({
            html: $('#alert-csv-popup').html(),
            overlayClose: false
        });
        return false;
    });

    $('a#alert-import-salesforce').click(function() {
        $.colorbox({
            html: $('#alert-salesforce-popup').html(),
            overlayClose: false
        });
        return false;
    });

    $('div.group-hover').click(function(e) {
        window.location.href = $(this).attr('rel');
    });

    $('a#join-group').click(function() {
        gGroupID = $(this).attr('rel');
        $.colorbox({
            html: $('#confirm-request-group').html(),
            overlayClose: false
        });
        return false;
    });

    $('a#add-connection-link').colorbox();

    $(document).on('click','a.group-already-exist-ok',function() {
        $.colorbox.close()
    });

    $('span[id^="update-request-info-"]').click(function(){
        $('.autocomplete-box').hide();
        $.colorbox({
            html: $('#update-open-request').html(),
            overlayClose: false,
            href: "#update-request"
        });
        var title = $(this).next().next().html();
        var message = $(this).next().next().next().html();
        var requestId = $(this).next().next().next().next().html();
        var tags = $(this).next().next().next().next().next().html();
        var forUserName = $(this).next().next().next().next().next().next().html();
        var forUserLinkedInID = $(this).next().next().next().next().next().next().html();
        tags = JSON.parse(tags);
        var tagIds = ""
        for(var i = 0; i < tags.length; i++) {
            tag = tags[i];
            tagName = tag.tagName;
            tagId = tag.tagId;
            $('div.tag-box').last().append('<span class="tagname"><a href="/groups/' + tagId.toString() + '">' + tagName + '</a><a href="#" class="delete-btn remove-group-from-request"></a></span><input type="hidden" value="'+ tagId + '" name="tag_id"/>');
            if(tagIds == "")
                tagIds = tagId.toString();
            else
                tagIds = tagIds + ',' + tagId.toString();
        }
        $('input[name=visibility_tags]').val(tagIds);
        $('input[name="title"]').last().val(title);
        $('textarea[name="message"]').last().val(message);
        $('input[name="request_id"]').last().val(requestId);
        $('input[name="query"]').last().val(forUserName);
        $('input[name="linkedin_id"]').last().val(forUserLinkedInID);
        $.colorbox.resize();
        requestAutoComplete();
        return false;
    });

    $('a[id^="update-request-info2-"]').click(function(){
        $('.autocomplete-box').hide();
        $.colorbox({
            html: $('#update-open-request').html(),
            overlayClose: false
        });
        var title = $(this).parent().next().html();
        var message = $(this).parent().next().next().html();
        var requestId = $(this).parent().next().next().next().html();
        var tags = $(this).parent().next().next().next().next().html();
        var forUserName = $(this).parent().next().next().next().next().next().html();
        var forUserLinkedInID = $(this).parent().next().next().next().next().next().next().html();
        tags = JSON.parse(tags);
        var tagIds = ""
        for(var i = 0; i < tags.length; i++) {
            tag = tags[i];
            tagName = tag.tagName;
            tagId = tag.tagId;
            $('div.tag-box').last().append('<span class="tagname"><a href="/groups/' + tagId.toString() + '">' + tagName + '</a><a href="#" class="delete-btn remove-group-from-request"></a></span><input type="hidden" value="'+ tagId + '" name="tag_id"/>');
            if(tagIds == "")
                tagIds = tagId.toString();
            else
                tagIds = tagIds + ',' + tagId.toString();
        }
        $('input[name=visibility_tags]').val(tagIds);
        $('input[name="title"]').last().val(title);
        $('textarea[name="message"]').last().val(message);
        $('input[name="request_id"]').last().val(requestId);
        $('input[name="query"]').last().val(forUserName);
        $('input[name="linkedin_id"]').last().val(forUserLinkedInID);
        $.colorbox.resize();
        requestAutoComplete();
        return false;
    });

    $('a.show-request-details').click(function() {
        $(this).parents('div').next('div.show-Rqst-details').show();
        return false;
    });

    $('.show-request-details2').click(function() {
        $(this).parents('td').prev().find('div.show-Rqst-details').show();
        return false;
    });

    $('a.hide-request-details').click(function() {
        $(this).parents('div.show-Rqst-details').hide()
        return false;
    });

    $('a.show-open-request-details').click(function() {
        $(this).next('div.show-sent-open-Rqst-details').show();
        $(this).hide();
        return false;
    });

    $('a.hide-open-request-details').click(function() {
        $(this).parents('div.show-sent-open-Rqst-details').hide()
        $(this).parents('div.show-sent-open-Rqst-details').prev().show();
        return false;
    });

    $('a.search-result-expand').click(function() {
        $(this).siblings('div.all-box-2').show();
        $(this).hide();
        $(this).siblings('a.search-result-collapse').show();
        return false;
    });

    $('a.search-result-collapse').click(function() {
        $(this).siblings('div.all-box-2').hide();
        $(this).siblings('a.search-result-expand').show();
        $(this).hide();
        return false;
    });

    $(document).on("click", "a.cancel-icon", function(){
        $(document).trigger('close.facebox');
    });

    $(document).mouseup(function (e)
    {
        if(e.target != "a.verification")
            $('div.tooltip').hide();
        if(e.target != "a.autocomplete-box" && e.target.offsetParent && e.target.offsetParent.className != "input-relative2")
            $('div.autocomplete-box:visible').hide();
//        if(e.target != "ul.list-container" && e.target.offsetParent && !e.target.offsetParent.className.match("listboxs2") && !e.target.offsetParent.className.match("checkboxBlue"))
//            $('div.listboxs2:visible').hide();
    });

    $('img.profile-settings , div.setting-icon').click(function(e) {
//        $('div.setting-icon').css('background', 'url("../assets/arrow.jpg") no-repeat scroll 0 -17px transparent');
        $('span.s-arrow').show();
        $('div.s-dropdown').show();
        e.stopPropagation();
    });

//    $(document).on('click','a.addtag',function () {
//        $(this).replaceWith('<span class="taginput-box" id="taginput"><input class="taginput" type="text" value="" name="" /><a href="#" class="delete-btn"></a></span>');
//        $('input.taginput').focus();
//        $.colorbox.resize();
//    });

    $(document).on('click','a.addtag,a.addtag-big',function () {
        $.colorbox({
            html: $('#new-group').html(),
            overlayClose: false
        });
        return false;
    });

    $(document).on('click','a.add-group-no-result',function () {
        $.colorbox({
            html: $('#create-group').html(),
            overlayClose: false
        });
    });

    $(document).on('click','a.search-group-submit',function(){
        $('.group-autocomplete-box table tbody').last().html("");
//        $('.search-group-loader').show();
        $('.search-group-submit').last().hide();
        $('.search-group-info').last().show();
        searchGroup();
        return false;
    });

    $(document).on('click','a.create-group',function(){
        $(this).hide();
        $('div.new-group-form').last().show();
        $('input[name=group-name]').last().val($('input[name=group]').last().val());
        $('input[name=group-admin]').last().val(userName);
        $.colorbox.resize();
        return false;
    });

    $(document).on('click','a#add-target', function(e){
        $(this).replaceWith('<input id="company-input" class="target-input" type="text" value="" name="" placeholder="E.g. Nike" />');
        $('input#company-input').focus();
        e.stopPropagation();
    });

    $(document).on('blur','input.target-input', function(e){
        company = $(this).val();
        if(company.match(/\S/)) {
            $(this).replaceWith('<span>' + company + '</span><a href="' + gRemoveCompanyPath + '" class="remove-company"></a>');
            $('div#company-box ul li').last().after('<li><a href="#" id="add-target">Add Target</a></li>');
            $('a#add-target').focus();
        }
        return false;
    });

    $(document).on('keydown','input.target-input', function(e){
        if(e.keyCode == 13){
            company = $(this).val();
            if(company.match(/\S/)) {
                $(this).replaceWith('<span>' + company + '</span><a href="' + gRemoveCompanyPath + '" class="remove-company"></a>');
                $('div#company-box ul li').last().after('<li><a href="#" id="add-target">Add Target</a></li>');
                $('a#add-target').focus();
            }
            return false;
        }
    });

    $(document).on('click','a.remove-company', function(){
        liToRemove = $(this);
        removePath = liToRemove.attr('href');
        if(removePath.match('/dummy')){
            liToRemove.parents('li').first().remove();
        }
        else {
            $.ajax({
                type: "POST",
                url: removePath,
                data: {},
                success: function(data) {
                    if(data.error == null && typeof data.error != "undefined") {
                        liToRemove.parents('li').first().remove();
                    }
                }
            });
        }
        return false;
    });

    $('form#multiple-search-form').submit(function() {
        queries = '';
        queryInputs = $('input[name^=multi-query]');
        for(i = 0; i < queryInputs.length; i++) {
            if(queries == '')
                queries = queryInputs[i].val();
            else
                queries = queries + ',' + queryInputs[i].val();
        }
        $('input[name=queries]').val(queries);
        return false;
    });

    $(document).on('click','a.delete-btn',function(e){
        $('span.taginput-box').replaceWith('<a href="#" class="addtag">Add a group</a>');
        $.colorbox.resize();
    });

    $(document).on('blur','input.taginput',function(e){
        tag = $(this).val();
        if (tag.match(/\S/)) {
            $.ajax({
                type: "POST",
                url: addGroupUrl,
                data: {tag_name: tag},
                success: function(data) {
                    $('.tagname').last().after('<span class="tagname"><a href="/groups/' + data.tagId + '">' + data.tagName + '</a> <a href="/delete_group/' + data.userTagId + '" class="delete-btn ajax-delete-tag"></a></span>');
                    $('span.taginput-box').replaceWith('<a href="#" class="addtag">Add a group</a>');
                    $.colorbox.resize();
                }
            });
        }
        else {
            $('span.taginput-box').replaceWith('<a href="#" class="addtag">Add a group</a>');
            $.colorbox.resize();
        }
        e.stopPropagation();
    });

    $(document).on('submit','form#new_open_request',function(){
        var title = $('input[name=title]').last().val();
        var message = $('textarea[name=message]').last().val();
        var titleError = true;
        var messageError = true;
        if(title.match(/\S/)) {
            $('span#open-request-title-error').hide();
            titleError = true;
        }
        else {
            $('span#open-request-title-error').show();
            titleError = false;
        }
        if(message.match(/\S/)) {
            $('span#open-request-message-error').hide();
            messageError = true;
        }
        else {
            $('span#open-request-message-error').show();
            messageError = false;
        }
        $.colorbox.resize();
        return (titleError && messageError);
    });

    $(document).on('submit','form#accept_request_form',function(){
        error = null;
        if($('.dataTables_empty').length > 0){
            if($( "input[id=other-connection]:checked" ).length > 0) {
                $('span#accept-request-connection-error').hide();
                error = true;
            }
            else {
                $('span#accept-request-connection-error').show();
                error = false;
            }
        }
        else {
            if($( "input[name=forUserAccountId]:checked" ).length > 0) {
                $('span#accept-request-connection-error').hide();
                error = true;
            }
            else {
                $('span#accept-request-connection-error').show();
                error = false;
            }
        }
        if(error) {
            $.ajax({
                type : 'POST',
                url : $(this).attr('action'),
                data : $(this).serialize(),
                dataType : 'json',
                success : function(data) {
                    if(data.error == null && typeof data.error != "undefined") {
                        fromUserName = data["fromUserName"];
                        forUserName = data["forUserName"];
                        toUserScore = data["updatedScore"];
                        toUserName = data["toUserName"];
                        fromUserEmail = data["fromUserEmail"];
                        content = data["content"];
                        fromUserNameArray = fromUserName.split(" ");
                        if(fromUserNameArray.length > 1)
                            fromUserFirstName = fromUserNameArray[0];
                        else
                            fromUserFirstName = fromUserName;
                        $('span#for-user-name-span').last().html(forUserName);
                        $('span#from-user-name-span').last().html(fromUserName);
                        $('span#to-user-score').last().html(toUserScore);
                        $('div.userscore').html(' ' + toUserScore);
                        $('div.accept-wrapper').last().hide();
                        $('div.accept-confirmation').last().show();
                        $.colorbox.element().parents('tr').remove();
                        $.colorbox.resize();
                        mailBody = "Hi  " + forUserName + "\n\nI wanted to introduce you to " + fromUserName + ".  A few words from " + fromUserFirstName + ":\n\n" + content + "\n\nI believe you two can benefit from a conversation. I will let you two take it from here.\n\nThanks!\n" + toUserName;
                        mailLink = "mailto:?cc=" + fromUserEmail + "&subject=Meet " + fromUserName + "&body=" + encodeURIComponent(mailBody);
                        document.location.href = mailLink;
                    }
                }
            });
        }
        return false;
    });

    $(document).on('submit','form#add_connection_form',function(){
        error = null;
        gCompanyMembersName = gTempCompanyMembersName;
        gCompanyMembersIds = gTempCompanyMembersIds;
        gTempCompanyMembersIdsArray = gTempCompanyMembersIds.split(',');
        gTempCompanyMembersNameArray = gTempCompanyMembersName.split('|');

        if(gTempCompanyMembersIdsArray.length > 0) {
            $('span#accept-request-connection-error').hide();
            error = true;
        }
        else {
            $('span#accept-request-connection-error').show();
            error = false;
        }

        if(error) {
            $('div#accounts-box ul li').not('[id=add-connection-li]').remove();
            for(i=0;i<gTempCompanyMembersIdsArray.length;i++) {
                if(typeof gTempCompanyMembersNameArray[i+1] != 'undefined' && gTempCompanyMembersIdsArray[i] != "") {
                    $('div#accounts-box ul li#add-connection-li').before('<li>' + gTempCompanyMembersNameArray[i+1] + '<input type="hidden" name="account_id" value="' + gTempCompanyMembersIdsArray[i] + '"></li>');
                }
                else {
                    idIndex = gTempCompanyMembersIdsArray.indexOf("undefined");
                    if(idIndex > -1)
                        gTempCompanyMembersIdsArray.splice(idIndex,1);
                    nameIndex = gTempCompanyMembersNameArray.indexOf("undefined");
                    if(nameIndex > -1)
                        gTempCompanyMembersNameArray.splice(nameIndex,1);
                    gTempCompanyMembersIds = gTempCompanyMembersIdsArray.join(',');
                    gTempCompanyMembersName = gTempCompanyMembersNameArray.join('|');
                }
            }
            $('a#add-connection-link').focus();
            $.colorbox.close();
        }
        return false;
    });

    $(document).on('click','form#add_connection_form input[name=userLinkedInId]',function(){
        gTempCompanyMembersIdsArray = gTempCompanyMembersIds.replace(/(^,)|(,$)/g, "").split(',');
        if(gTempCompanyMembersIdsArray[0] == "")
            gTempCompanyMembersIdsArray.splice(0,1);
        gTempCompanyMembersNameArray = gTempCompanyMembersName.split('|');
        id = $(this).val();
        name = $(this).parents('td').next().find('span').text();
        if(id == "private" || name == "private private"){
            return;
        }
        else if($(this).is(':checked')) {
            gTempCompanyMembersIdsArray.push(id);
            gTempCompanyMembersNameArray.push(name);
        }
        else {
            idIndex = gTempCompanyMembersIdsArray.indexOf(id);
            if(idIndex > -1)
                gTempCompanyMembersIdsArray.splice(idIndex,1);
            nameIndex = gTempCompanyMembersNameArray.indexOf(name);
            if(nameIndex > -1)
                gTempCompanyMembersNameArray.splice(nameIndex,1);
        }
        gTempCompanyMembersIds = gTempCompanyMembersIdsArray.join(',');
        gTempCompanyMembersName = gTempCompanyMembersNameArray.join('|');
    });

    $(document).on('click','input#multi-company-search',function(){
        accounts = "";
        accountElements = $('div#company-box ul li span');
        for(i=0;i<accountElements.length;i++) {
            if(accounts == "")
                accounts = $(accountElements[i]).html();
            else
                accounts = accounts + ',' + $(accountElements[i]).html();
        }
        $('input[name=accounts]').val(accounts);

        connections = [];
        connectionElements = $('div#accounts-box ul li').not('[id=add-connection-li]');
        for(i=0;i<connectionElements.length;i++) {
            connections.push({
                "connectionName" : $.trim($(connectionElements[i]).text()),
                "connectionId" : $(connectionElements[i]).find('input').val()
            });
        }
        $('input[name=connections]').val(JSON.stringify(connections));

        companyElements = $('div#company-box ul li span');
        if(companyElements.length > 0) {
            companies = [];
            for(i=0;i<companyElements.length;i++) {
                companies.push({
                    "company" : $(companyElements[i]).html(),
                    "start" : 0
                });
            }
            $('input#multi-companies-input').val(JSON.stringify(companies));
            $('form#multi-company-search-form').submit();
        }
        else {
            $('span#target-account-error').show();
            return false;
        }
    });

    $(document).on('submit','form#add-admin-to-group-form',function(){
        error = null;
        if($('input[name="user_id"]').last().val().match(/\S/)) {
            $('span#add-admin-to-group-error').hide();
            error = true;
        }
        else {
            $('span#add-admin-to-group-error').show();
            error = false;
        }
        $.colorbox.resize();
        return error;
    });

    $(document).on('submit','form#new-group-form',function(){
        fileError = null;
        descriptionError = null;
        if($('textarea[name=description-message]').last().val().match(/\S/)) {
            $('span#group-description-error').last().hide();
            descriptionError = false;
        }
        else {
            $('span#group-description-error').last().show();
            descriptionError = true;
        }
        if($('input[type=file]').last().val().match(/\S/)) {
            $('span#group-logo-error').last().hide();
            fileError = false;
        }
        else {
            $('span#group-logo-error').last().show();
            fileError = true;
        }
        $.colorbox.resize();
        return (!fileError && !descriptionError);
    });

    $(document).on('submit','form#request-group-form',function(){
        error = null;
        if($('input[name=group-id]').last().val().match(/\S/)) {
            $('span#group-name-error').hide();
            error = true;
        }
        else {
            $('span#group-name-error').hide();
            error = false;
        }
        $.colorbox.resize();
        return error;
    });

    $(document).on('submit','form#group-request-confirm-form',function(){
        $('input[name=group-id]').val(gGroupID);
        gGroupID = null;
    });

    $(document).on('click','a.ajax-delete-tag',function(e){
        var element_remove = $(this).parent('span');
        $.ajax({
            type: 'GET',
            url: $(this).attr('href'),
            success: function(data){
                if( data.isDeleted == true ) {
                    element_remove.remove();
                }
            }
        });
        $.colorbox.resize();
        return false;
    });

    $(document).on('click','a.remove-group-from-request',function(e){
        var element_remove = $(this).parent('span');
        tagId = element_remove.next().val();
        visibilityTagsArray = $('input[name=visibility_tags]').last().val().split(',');
        index = visibilityTagsArray.indexOf(tagId);
        if(index > -1 && visibilityTagsArray.length > 1) {
            visibilityTagsArray.splice(index, 1);
            $('input[name=visibility_tags]').last().val(visibilityTagsArray.join(','));
            element_remove.next().remove();
            element_remove.remove();
            $.colorbox.resize();
        }
        return false;
    });

//    Commented due to bug#333
    $(document).on('change','input:radio[name="private"]',function(){
        if ($(this).val() == 'private') {
            $('div#open-request-tags').show();
        }
        else {
            $('div#open-request-tags').hide();
        }
        $.colorbox.resize();
    });

    $("#showfilter").click(function(){
        $("#filter-option-box").slideDown();
        $("#hidefilter").show();
        $("#showfilter").hide();
    });

    $("#hidefilter").click(function(){
        $("#filter-option-box").slideUp();
        $("#showfilter").show();
        $("#hidefilter").hide();
    });

    // Commented due to bug#184
//    $('input[name="above-80-filter"]').click(function(){
//        var score = null;
//        if($(this).is(':checked')) {
//            score = 81;
//        }
//        else {
//            score = 0;
//        }
//        $('input[name=all-request-filter]').prop('checked', false);
//        $('input#dataTable-request-filter_range_from_3').val(score);
//        $('input#dataTable-request-filter_range_from_3').trigger('keyup');
//    });

//    $('input[name="all-request-filter"]').click(function(){
//        if($(this).is(':checked')) {
//            $( "input:checkbox" ).prop('checked', false);
//            $(this).prop('checked', true);
//        }
//        $('input#dataTable-request-filter_range_from_3').val('');
//        $('span.filter_column input.text_filter').last().val('');
//        $('input#dataTable-request-filter_range_from_3').trigger('keyup');
//        $('span.filter_column input.text_filter').last().trigger('keyup');
//    });

    $('input[name="tag-filter"]').click(function(){
        var tag = '';
        $.each($( "input[name=tag-filter]:checked" ), function(index, value) {
            if(index == 0)
                tag = $(value).parents().next().html();
            else
                tag = tag + '|' + $(value).parents().next().html();
        });
        if(!tag.match(/\S/))
            tag = "noResultsShouldBeDisplayed";
//        $('input[name=all-request-filter]').prop('checked', false);
        $('span.filter_column input.text_filter').last().val(tag);
        $('span.filter_column input.text_filter').last().trigger('keyup');
    });

    $(document).on('click','div.autocomplete-box table tbody tr',function(){
        $('input[name=linkedin_id]').last().val($(this).find('p').first().html());
        if ($('input[name=first_name]').exists()) {
            $('input[name=first_name]').last().val($(this).find('p').first().next().html());
        }
        if ($('input[name=last_name]').exists()) {
            $('input[name=last_name]').last().val($(this).find('p').first().next().next().html());
        }
        $('input.request_connection_search:visible').last().val($(this).first().find('span').first().html());
        $('input[name=query]:visible').last().focus();
        $('input[name=query]:visible').last().css('font-style','normal');
        $('div.autocomplete-box').fadeOut();
    });

    $(document).on('click','div.group-autocomplete-box table tbody tr',function(){
        $('input[name=group]').last().val($(this).find('td').last().html());
        var isAlreadyMemberInTag = $(this).find('td').last().next().attr('rel');
        if(isAlreadyMemberInTag === 'true') {
            $('p.already-part').last().show();
            $('a.group-already-exist-ok').last().show();
        }
        else {
            $('input[name=group-id]').last().val($(this).find('td').last().next().val());
            $('div.group-exist').last().show();
        }
        $('div.group-autocomplete-box').last().hide();
        $('input[name=group]').last().focus();
        $('input[name=group]').last().css('font-style','normal');
        $.colorbox.resize();
    });

    $(document).on('click','div.admin-autocomplete-box table tbody tr',function(){
        $('input[name=member]').last().val($(this).find('td').last().html());
        $('input[name=user_id]').last().val($(this).find('td').last().next().val());
        $('input[name=member]').last().focus();
        $('input[name=member]').last().css('font-style','normal');
        $('div.admin-autocomplete-box').hide();
        $.colorbox.resize();
        return false;
    });

    $(document).on('keyup','input[name=query]',function(){
        if($(this).val().length < 4) {
            $(this).parent('div').find('.autocomplete-box').fadeOut();
        }
        else if($(this).val().length > 3) {
            $(this).parent('div').find('.autocomplete-box table tbody').html("");
            $(this).parent('div').find('.search-connection-no-result').hide();
            $(this).parent('div').find('.search-connection-loader').show();
            $(this).parent('div').find('.autocomplete-box').fadeIn();
        }
    });

    $(document).on('keyup','input[name=member]',function(){
        if($('.admin-search').last().val().length < 4) {
            $('.admin-autocomplete-box').hide();
        }
        else if($('.admin-search').last().val().length > 3) {
            $('.admin-autocomplete-box table tbody').html("");
            $('.search-connection-no-result').hide();
            $('.search-connection-loader').show();
            $('.admin-autocomplete-box').show();
        }
        $.colorbox.resize();
    });

    $(document).on('keyup','input[name=person-name]',function(){
        if($(this).val().length < 4) {
            $(this).parent('div').find('.person-autocomplete-box').fadeOut();
        }
        else if($(this).val().length > 3) {
            $(this).parent('div').find('.person-autocomplete-box table tbody').html("");
            $(this).parent('div').find('.search-connection-no-result').hide();
            $(this).parent('div').find('.search-connection-loader').show();
            $(this).parent('div').find('.person-autocomplete-box').fadeIn();
        }
    });

    $(document).on('click','input[name=industries]',function(){
        $('.listboxs2').hide();
        var inputElement = $('input[name="industries"]');
        inputElement.parents('div.input_block').find('div.listboxs2').show();
    });

    $(document).on('click','input[name=locations]',function(){
        $('.listboxs2').hide();
        var inputElement = $('input[name="locations"]');
        inputElement.parents('div.input_block').find('div.listboxs2').show();
    });

    $(document).on('click','a#downarrow-expand',function() {
        $('.admin-autocomplete-box').show();
        $.colorbox.resize();
    });

    $(".more-colorbox-popup").click(function(){
        gMoreInfoElement = $(this).parents('tr');
        gMoreInfoName = $(this).parents('tr').find('.USR-info span a').first().text();
    });

    $(".more-colorbox-popup").colorbox({
        initialWidth: 556,
        initialHeight:149,
        onComplete:function(){
            gMoreInfoElement.remove();
            $('.more_info_name_span').text(gMoreInfoName);
            $.colorbox.resize();
            gMoreInfoElement, gMoreInfoName = null;
        }
    });

    $(document).on('click','div.autocomplete-box',function() {
        if($('div.autocomplete-box').find('tr').length == 0) {
            $('input[name=linkedin_id]').last().val('');
            $('input[name=first_name]').last().val('');
            $('input[name=last_name]').last().val('');
            $('input[name=query]').last().focus();
            $('input[name=query]').last().css('font-style','normal');
            $('.autocomplete-box').fadeOut();
        }
        return false;
    });

    $(".ignore-request").click(function(){
        gIgnoreElement = $(this).parents('tr');
        gIgnoredName = $(this).parents('tr').find('.USR-info span a').first().text();
    });

    $(".verification").click(function(){
        $(this).parents('div').prev().find('div.tooltip').show();
        return false;
    });

    $(document).on('mouseenter mouseleave','.red-flag', function() {
        $(this).find('div.tooltip').toggle();
    });

    $(".ignore-request").colorbox({
        initialWidth: 556,
        initialHeight:149,
        onComplete:function(){
            gIgnoreElement.remove();
            $('.ignored_name_span').last().text(gIgnoredName);
            $.colorbox.resize();
            gIgnoreElement, gIgnoredName = null;
        }
    });

    $(document).on('submit','form#add-member-to-group',function() {
        var emailError = true;
        var queryError = true;
        var nameArray = $(this).find('input[name=query]');
        var emailArray = $(this).find('input[name=email]');
        for(i=0;i<nameArray.length;i++) {
            nameElement = $(nameArray[i]);
            if(nameElement.val().match(/\S/)) {
                nameElement.prev().find('span').hide();
                queryError = true;
            }
            else {
                nameElement.prev().find('span').show();
                queryError = false;
            }
        }
        for(i=0;i<emailArray.length;i++) {
            emailElement = $(emailArray[i]);
            if(emailElement.val().match(/\S/) && emailElement.val().match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/)) {
                emailElement.prev().find('span').hide();
                emailError =true;
            }
            else {
                emailElement.prev().find('span').show();
                emailError = false;
            }
        }
        if($('.invite-member-row:visible').length < 3) {
            $.colorbox.resize();
        }
        if (emailError && queryError) {
            tag_id = $('input[name=invite_member_tag_id]').val();
            nameJson = [];
            for(i=0;i<nameArray.length;i++) {
                nameJson.push($(nameArray[i]).val());
            }
            emailJson = [];
            for(i=0;i<emailArray.length;i++) {
                emailJson.push($(emailArray[i]).val());
            }
            $.ajax({
                type : 'POST',
                url : $(this).attr('action'),
                data : {names:nameJson,emails:emailJson,tag_id:tag_id},
                dataType : 'json',
                success : function(data) {
//                    if(data.error == null && typeof data.error != "undefined") {
//                        if(data.isAlreadyMemberInTag) {
//                            $('span.already-exist2').last().show();
//                            $.colorbox.resize();
//                        }
//                        else {
//                            $.colorbox.close();
//                        }
//                    }
//                    else {
                    $.colorbox.close();
//                    }
                }
            });
        }
        return false;
    });

    $(document).on('click','a#add-more-members',function() {
        content = $('div#add-more-members-content').html();
        $('div.invite-member-row').last().after(content);
        if($('.invite-member-row:visible').length == 2) {
            $.colorbox.resize();
        }
        else {
            $('div#cboxLoadedContent').css('overflow-x','hidden');
        }
        $(this).focus();
        return false;
    });

    $(document).on('click','div.group-upload-button',function() {
        //$('input#uploadfile').last().click();
        //return false;
    });

    $(document).on('click','a.add-csv-file',function() {
        $('input.add-csv-input').last().click();
        return false;
    });

    $(document).on('click','a.alert-csv-file',function() {
        $('input.alert-csv-input').last().click();
        return false;
    });

    $(document).on('click','input.company-filter',function() {
        applyOnlyCompanyConnectionsFilter();
    });

    $(document).on('click','input#only-company-filter',function() {
        applyOnlyCompanyConnectionsFilter();
    });

    $(document).on('keyup','input[name=search-alerts]',function() {
        applySearchAlertsFilter(this);
    });

    $(document).on('submit','tr.show-more-company-results form',function() {
        $(this).find('img.show-more-loader').show();
        var companyToRemove = $(this).find('input[name=query]').val();
        var elementToScroll = $("tr[class*='" + companyToRemove + "']").last().prev();
        gShowMoreElementToRemove = $(this).parents('tr.show-more-company-results');
        $.post(
            $(this).attr('action'),
            $(this).serialize(),
            function(data) {
                gCompanyFilter.fnDestroy();
                gShowMoreElementToRemove.remove();
                $("tr[class*='" + companyToRemove + "']").last().remove();
                $('div.sent_received_section table tbody').append(data);
                $('html, body').animate({
                    scrollTop: elementToScroll.next().offset().top
                }, 500);
            });
        return false;
    });

    $(document).on('submit','form#search-existing-show-more',function() {
        $(this).find('img.show-more-loader').show();
        var elementToScroll = $('tr.USR-details-box').last();
        $.post(
            $(this).attr('action'),
            $(this).serialize(),
            function(data) {
                $('tr#show-more-parent-node').remove();
                $('div.sent_received_section table tbody').append(data);
                $('html, body').animate({
                    scrollTop: elementToScroll.next().offset().top
                }, 500);
            });
        return false;
    });

    $(document).on('submit','form#import-csv-form',function(){
        fileError = false;
        if($('input.add-csv-input').last().val().match(/\S/)) {
            $('span#group-csv-error').last().hide();
            fileError = true;
        }
        else {
            $('span#group-csv-error').last().show();
            fileError = false;
        }
        if(fileError) {
            $(this).ajaxSubmit({
                beforeSubmit: function(a,f,o) {
                    o.dataType = 'html';
                },
                success: function(data, status) {
                    switch(data) {
                        case "NO_EMAIL":
                            $('div.import-group-csv-box').last().html("No email found in csv");
                            break;
                        case "INVALID_FORMAT":
                            $('div.import-group-csv-box').last().html("Please upload a valid csv file");
                            break;
                        default:
                            $('div.import-group-csv-box').last().hide();
                            $('table#import-results tbody').last().append(data);
                            $('div.import-group-csv-result-box').last().show();
                            $.colorbox.resize();
                    }
                }
            });
        }
        return false;
    });

    $(document).on('submit','form#alert-csv-form',function(){
        fileError = false;
        $('input.alert-csv-submit').last().hide();
        $('.alert-csv-loader').last().show();
        if($('input.alert-csv-input').last().val().match(/\S/)) {
            $('span#alert-csv-error').last().hide();
            fileError = true;
        }
        else {
            $('span#alert-csv-error').last().show();
            fileError = false;
        }
        if(fileError) {
            $(this).ajaxSubmit({
                beforeSubmit: function(a,f,o) {
                    o.dataType = 'html';
                },
                success: function(data, status) {
                    switch(data) {
                        case "NO_COMPANY":
                            $('div.import-alert-csv-box').last().html("No company found in csv");
                            break;
                        case "INVALID_FORMAT":
                            $('div.import-alert-csv-box').last().html("Please upload a valid csv/xlsx file");
                            break;
                        default:
                            location.reload();
                    }
                }
            });
        }
        return false;
    });


    $(document).on('click','.update_connection_strength_input',function(){
        $('input[name=connectionsStrengthJson]').val(JSON.stringify(gConnectionsStrength));
        $('form#update_connection_strength_form').submit();
    });

    $(document).on('submit','form.add-to-salesforce-form',function(){
        elementToHide = $(this);
        $.post(
            $(this).attr('action'),
            $(this).serialize(),
            function(data) {
                if(data.error == null && typeof data.error != "undefined") {
                    elementToHide.hide();
                    elementToHide.prev().show();
                    elementToHide.parents('div').first().attr('style','width : 80%');
                }
            }
        );
        return false;
    });

    $(document).on('submit','form.mark-to-salesforce-form',function(){
        $.post(
            $(this).attr('action'),
            $(this).serialize(),
            function(data) {
            }
        );
        return false;
    });
    $(document).on('click','#show-salesforce-target-form',function(){
        $('div#salesforce-target-form').slideToggle();
        $(this).find('img').toggle();
    });

    $(document).on('blur','input#dr-target-input', function(e){
        target = $(this).val();
        if(target.match(/\S/)) {
            $(this).before('<li>' + target + ' <span><a href="#" class="dr-remove-target"></a></span></li>');
            $(this).val('');
            $(this).hide();
        }
        return false;
    });

    $(document).on('keydown','input#dr-target-input', function(e){
        if(e.keyCode == 13){
            target = $(this).val();
            if(target.match(/\S/)) {
                $(this).before('<li>' + target + ' <span><a href="#" class="dr-remove-target"></a></span></li>');
                $(this).val('');
                $(this).hide();
            }
            return false;
        }
    });

//    $(document).on('click','.ofunnel-alerts .downarrow', function() {
//        $(this).nextAll('.alert-autocomplete-box').toggle();
//        return false;
//    });
//
//    $(document).on('click','.alert-autocomplete-box tr td',function() {
//        type = $(this).text();
//        $(this).parents('div.alert-autocomplete-box').prevAll('input[name=type]').val(type);
//        $(this).parents('div.alert-autocomplete-box').toggle();
//        return false;
//    });

    $(document).on('click','a#alert-add-target-account',function(){
        if($('input[name=query]:visible').last().val() != "") {
            $('div.alert-details').append($('div.extra-alert-container').html());
            initialiseSelectBox();
        }
        $('input.name-select:visible').last().focus();
        return false;
    });

    $(document).on('change',".alert-type",function() {
        console.log("Select box changed");
        searchPeopleForQuery();
        $(this).parents('.ofunnel-alerts').find('.autocomplete-box:visible').hide();

        if($(this).val() == 'Person') {
            $(this).parents('.ofunnel-alerts').find('input.normal:visible').hide();
            $(this).parents('.ofunnel-alerts').find('input.person').show();
            $(this).parents('.ofunnel-alerts').find('a.person-downarrow').show();
        }
        else {
            $(this).parents('.ofunnel-alerts').find('input.normal').show();
            $(this).parents('.ofunnel-alerts').find('input.person').hide();
            $(this).parents('.ofunnel-alerts').find('a.person-downarrow:visible').hide();
        }
    });

    $(document).on('click','a.alert-remove-target',function(){
        removePath = $(this).attr('href');
        elementToRemove = $(this).parents('div.ofunnel-alerts');
        if(removePath.match('/dummy')){
            elementToRemove.remove();
        }
        else {
            $.ajax({
                type : 'POST',
                url : removePath,
                data : {},
                dataType : 'json',
                success : function(data) {
                    if(data.error == null && typeof data.error != "undefined") {
                        elementToRemove.remove();
                    }
                }
            });
        }
        return false;
    });

    $(document).on('click','a.delete-target-account',function(){
        removePath = $(this).attr('href');
        elementToRemove = $(this).parents('tr');
        if(removePath.match('/dummy')){
            elementToRemove.remove();
        }
        else {
            $.ajax({
                type : 'POST',
                url : removePath,
                data : {},
                dataType : 'json',
                success : function(data) {
                    if(data.error == null && typeof data.error != "undefined") {
                        elementToRemove.remove();
                        if ($(this).parent().parent('tr.active').length > 0)
                            hideSimilarCompanyBox();
                        else
                            adjustSimilarBox($("div.alerts_details table tr.active").index() - 1);
                    }
                }
            });
        }
        return false;
    });

    $(document).on('submit','form#add_relationships_form',function(){
        targetAlerts = $('div.ofunnel-alerts:visible');
        i = 0;
        targetAlerts.each(function() {
            if($(this).find('input.name-select:visible').val() != "")
                i++;
        });
        if(i < 1) {
            $('span#alert-target-account-error').show();
            return false;
        }
        else {
            alertJson = [];
            targetAlerts.each(function() {
                type = $(this).find('select.alert-type').val();
                name = $(this).find('input.name-select:visible').val();
                alertId = $(this).find('input[name=alertId]').val();
                if(type != "" && name != "")
                    alertJson.push({
                        "type" : type,
                        "name" : name,
                        "alertId" : alertId
                    });
            });
            $('input[name=alertJson]').val(JSON.stringify(alertJson));
            $('span#alert-target-account-error').hide();
        }
    });

    $(document).on('click','#add-recipient',function(){
        $('#add-recipient-form').toggle();
        $('#add-recipient span').toggleText('▼','►');
        return false;
    });

    $(document).on('click','a#alert-add-recipient',function() {
        text = $('div.recipient-box input').last().val();
        if(typeof text == "undefined" || text.match(/\S/))
            $(this).parent().before('<div class="recipient-box all-box-3 mrg-T15"><input class="input-field" type="text" name="email" value="" placeholder="johnathanjones@companyxyz.com"><a href="#" class="delete-icon2 alert-remove-recipient2"></a></div>');
        return false;
    });

    $(document).on('click','a.alert-remove-recipient',function() {
        url = $(this).attr("href");
        $.ajax({
            type : 'POST',
            url : url,
            data : {},
            success : function(data) { }
        });
        return false;
    });

    $(document).on('click','a.alert-remove-recipient2',function() {
        $(this).parent().remove();
        return false;
    });

    $(document).on('submit','form#add-recipient-form',function() {
        submitForm = true;
        $.each($(this).find('input.input-field'),function(index, value) {
            if(!($(value).val().match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/))) {
                $('div.add-recipient-error').show();
                submitForm = false;
            }
        });
        if(submitForm) {
            $('div.add-recipient-error').hide();
            recipientArray = [];
            $.each($(this).find('input.input-field'),function(index, value) {
                recipientArray.push($(value).val());
            });
            if(recipientArray.length > 0)
                $.ajax({
                    type : 'POST',
                    url : $(this).attr('action'),
                    data : {recipientEmails:recipientArray},
                    success : function(data) {
//                    if(data == "SUCCESS") {
//                        $('.add-recipient-confirmation').show();
//                        $('.add-recipient-confirmation').delay(5000).fadeOut();
//                    }
                    }
                });
        }
        return false;
    });

    $(document).on('click','a.delete-alert-recipient',function() {
        url = $(this).attr("href");
        elementToRemove = $(this).parents('li');
        $.ajax({
            type : 'POST',
            url : url,
            data : {},
            success : function(data) {
                elementToRemove.remove();
            }
        });
        return false;
    });

    $(document).on('click','a.delete-alert-recipient2',function() {
        $(this).parents('li').remove();
        return false;
    });

    $(document).on('blur','input[name=recipient-email]',function() {
        value = $(this).val();
        if(value.match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/))
            $(this).parent().parent().replaceWith('<li><label class="disable_text">' +
                value +
                '</label><span>' +
                '<a class="delete-alert-recipient2" href="#"><img src="assets/delete_icon.png" width="20" height="19" alt="delete">' +
                '</a></span></li>');
        return false;
    });

    $(document).on('click','a.add-alert-recipient',function() {
        if($('input[name=recipient-email]').length == 0)
            $('div.alert_recipients ul').append('<li><div class="input_block mrg-T10 mrg-B10"><input type="text" class="inputbox outline-none" placeholder="abc@xyz.com" name="recipient-email" value=""><a href="#" class="float-R edit_icn"><img src="/assets/edit_icon2.png" width="11" height="10" alt="edit"></a></div></li>');
        return false;
    });

    $(document).on('submit','form#alert-recipient-form',function() {
        submitForm = true;
        $.each($(this).find('input[name=recipient-email]'),function(index, value) {
            if($(value).val().match(/\S/) && !($(value).val().match(/^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/))) {
                $('span.add-recipient-error').show();
                submitForm = false;
                return false;
            }
        });
        if(submitForm) {
            $('span.add-recipient-error').hide();
            recipientArray = [];
            $.each($('div.alert_recipients ul li label'),function(index, value) {
                if($(value).text().match(/\S/))
                    recipientArray.push($(value).text());
            });
            $.each($(this).find('input[name=recipient-email]'),function(index, value) {
                if($(value).val().match(/\S/))
                    recipientArray.push($(value).val());
            });
            if(recipientArray.length > 0)
                $.ajax({
                    type : 'POST',
                    url : $(this).attr('action'),
                    data : {recipientEmails:recipientArray},
                    success : function(data) {
                        if(data == "SUCCESS") { }
                    }
                });
        }
        return false;
    });

    $('input.name-select').click(function(){
        initializeRecipientAutoComplete(this);
    });

    $('input.name-select').select(function(){
        initializeRecipientAutoComplete(this);
    });

    $(document).on('click','a.add-to-salesforce-crm',function() {
        elementToChange = $(this);
        url = elementToChange.attr("href");
        firstName = elementToChange.attr("firstName");
        lastName = elementToChange.attr("lastName");
        title = elementToChange.attr("title");
        company = elementToChange.attr("company");
        $.ajax({
            type : 'POST',
            url : url,
            data : {firstName:firstName,lastName:lastName,title:title,company:company},
            success : function(data) {
                if(data == "SUCCESS") {
                    elementToChange.parent().html("Added");
                }
                else if(data != "ERROR") {
                    window.location.href = data;

                }
            }
        });
        return false;
    });

    $(document).on('change','input[name=filter-type]',function(){
        $('tr[id$="-filter"]').hide();
        $('tr[class$="-slf"]').hide();
        $('p.Company-slf').hide()
        $('p.Person-slf').hide()
        $('tr#' + $(this).val() + '-filter').show();
        $('.' + $(this).val() + '-slf').show();
        $("div[class*='-flf-error']").hide();
    });

    $(document).on('mouseenter','td.filter-tooltip-container',function(){
        $('div.arrow_box').not($(this).find('div.arrow_box')).hide();
        $(this).find('div.arrow_box').show();
        return false;
    });

    $(document).on('mouseleave','td.filter-tooltip-container',function(){
        $(this).find('div.arrow_box').hide();
        return false;
    });

    $(document).on('click','.remove-darkgray',function(e){
        if($(this).parents('div.input_block').find('a.remove-darkgray').length == 1) {
            if($(this).parent('span').hasClass('industry'))
                $('input[name="industries"]').attr('placeholder','Any Industry').attr('onblur',"this.placeholder = 'Any Industry'");
            else if($(this).parent('span').hasClass('location'))
                $('input[name="locations"]').attr('placeholder','Anywhere').attr('onblur',"this.placeholder = 'Anywhere'");
            else if($(this).parent('span').hasClass('company'))
                $('input[name="company2"]').attr('placeholder','Any Company').attr('onblur',"this.placeholder = 'Any Company'");
            else if($(this).parent('span').hasClass('role'))
                $('input[name="role2"]').attr('placeholder',' Any Role').attr('onblur',"this.placeholder = ' Any Role'");
        }
        $(this).parent('span.darkgray').remove();
        id = $(this).attr('rel');
        $('input#checkboxFourInput-' + id).prop('checked', false).parents('li').removeClass('selected2');
        return false;
    });

    $(document).on('click','div.person-autocomplete-box table tbody tr',function() {
        $('input[name=person-name]').val($(this).find('td span').first().html());
        $(this).parents('div').first().hide();
        return false;
    });

    $(document).on('blur','input[name=role2]',function(){
        addRoleFilter(this);
        return false;
    });

    $(document).on('keypress','input[name=role2]',function(event) {
        if (event.keyCode == 13) {
            addRoleFilter(this);
            event.preventDefault();
        }
    });

    $(document).on('blur','input[name=company2]',function(){
        addCompanyFilter(this);
        return false
    });

    $(document).on('keypress','input[name=company2]',function(event) {
        if (event.keyCode == 13) {
            addCompanyFilter(this);
            event.preventDefault();
        }
    });

    $(document).on('click','.add-alert-industry',function(){
        $(this).parents('div.pos-Rel').before('<span class="industry darkgray mrg-L5 mrg-T5">' +
            $(this).html() + '<a class="remove-darkgray" href="#">' +
            '<img src="/assets/close.png" width="8" height="8" alt="close">' +
            '</a></span>');
        $('input[name="industries"]').attr('placeholder','').attr('onblur',"this.placeholder = ''");
        return false;
    });

    $(document).on('click','.add-alert-location',function(){
        $(this).parents('div.pos-Rel').before('<span class="location darkgray mrg-L5 mrg-T5">' +
            $(this).html() + '<a class="remove-darkgray" href="#">' +
            '<img src="/assets/close.png" width="8" height="8" alt="close">' +
            '</a></span>');
        $('input[name="locations"]').attr('placeholder','').attr('onblur',"this.placeholder = ''");
        return false;
    });

    $(document).on('submit','form.save-alert-changes',function() {
        $('span.alert-error').hide();
        if($('input[name$=-name]:visible').val().match(/\S/)) {
            // Get first level filter details
            filterType = $('input[name=filter-type]:checked').val();
            targetName = $('input[name$=-name]:visible').val();
            targetAccountId = $('input[name=alertId]').val();
            companySizeFilter = [];
            industryFilter = [];
            locationFilter = [];
            companyFilter = [];
            roleFilter = [];
            secondLevelFilterDetails = [];

            // Get second level filter details
            $.each($('input[name=size-filter]:checked:visible'), function( index, value ) {
                if($(value).val() != "Any")
                    companySizeFilter.push({
                        filterText : $(value).val()
                    })
            });

            $.each($('span.company:visible'), function( index, value ) {
                companyFilter.push({
                    filterText : $.trim($(value).text())
                })
            });

            $.each($('span.role:visible'), function( index, value ) {
                roleFilter.push({
                    filterText : $.trim($(value).text())
                })
            });

            $.each($('span.industry:visible'), function( index, value ) {
                industryFilter.push({
                    filterText : $.trim($(value).text())
                })
            });

            $.each($('span.location:visible'), function( index, value ) {
                locationFilter.push({
                    filterText : $.trim($(value).text())
                })
            });

            //Fill second level filter details in JSON
            if(companyFilter.length > 0) {
                secondLevelFilterDetails.push(
                    {
                        subFilterType : "COMPANY",
                        filterTextDetails : companyFilter
                    }
                );
            }

            if(roleFilter.length > 0) {
                secondLevelFilterDetails.push(
                    {
                        subFilterType : "ROLE",
                        filterTextDetails : roleFilter
                    }
                );
            }

            if(companySizeFilter.length > 0) {
                secondLevelFilterDetails.push(
                    {
                        subFilterType : "COMPANYSIZE",
                        filterTextDetails : companySizeFilter
                    }
                );
            }

            if(industryFilter.length > 0) {
                secondLevelFilterDetails.push(
                    {
                        subFilterType : "INDUSTRY",
                        filterTextDetails : industryFilter
                    }
                );
            }

            if(locationFilter.length > 0) {
                secondLevelFilterDetails.push(
                    {
                        subFilterType : "LOCATION",
                        filterTextDetails : locationFilter
                    }
                );
            }

            targetAccountJson = [
                {
                    filterType : filterType,
                    targetName : targetName,
                    targetAccountId : targetAccountId,
                    secondLevelFilterDetails : secondLevelFilterDetails
                }
            ]
            $.ajax({
                type : 'POST',
                url : $(this).attr('action'),
                data : {targetAccount : JSON.stringify(targetAccountJson)},
                success : function(data) {
                    window.location.href = alertsPagePath;
                }
            });
        }
        else {
            $("div[class*='-flf-error']").hide();
            $('div.' + $('input[name=filter-type]:checked').val() + '-flf-error').show();
        }
        return false;
    });

    $(document).on('click','a.close-listbox2',function() {
        $('div.listboxs2').hide();
        $(this).parents('div.input_block').find('div.pos-Rel span input').val("");
        return false;
    });

    $(document).on('click','li.category',function() {
        id = $(this).attr('rel');
        $('li.selected2').removeClass('selected2');
        $(this).addClass('selected2');
        $('div.sub-category').hide();
        $('div#' + id.replace(/\s/g,'')).show();
        return false;
    });

    $(document).on('change','input[id^=checkboxFourInput-industry-]',function() {
        if($(this).is(':checked')) {
            $(this).parents('div.input_block').find('div.pos-Rel').before('<span class="industry darkgray mrg-L5 mrg-T5">' +
                $(this).val() + '<a class="remove-darkgray" href="#" rel="' + $(this).attr('rel') + '">' +
                '<img src="/assets/close.png" width="8" height="8" alt="close">' +
                '</a></span>');
        }
        else {
            id = $(this).attr('rel');
            $(this).parents('div.input_block').find('a[rel="' + id + '"]').parent('span').remove();
        }
        $('input[name="industries"]').attr('placeholder','').attr('onblur',"this.placeholder = ''");
        $(this).parents('li').toggleClass('selected2');
        return false;
    });

    $(document).on('change','input[id^=checkboxFourInput-location-]',function() {
        if($(this).is(':checked')) {
            $(this).parents('div.input_block').find('div.pos-Rel').before('<span class="location darkgray mrg-L5 mrg-T5">' +
                $(this).val() + '<a class="remove-darkgray" href="#" rel="' + $(this).attr('rel') + '">' +
                '<img src="/assets/close.png" width="8" height="8" alt="close">' +
                '</a></span>');
        }
        else {
            id = $(this).attr('rel');
            $(this).parents('div.input_block').find('a[rel="' + id + '"]').parent('span').remove();
        }
        $('input[name="industries"]').attr('placeholder','').attr('onblur',"this.placeholder = ''");
        $(this).parents('li').toggleClass('selected2');
        return false;
    });

    $(document).on('change','input[name=notification_frequency]',function() {
        frequency = $(this).val();
        $.ajax({
            type : 'POST',
            url : notificationFrequencyUrl,
            data : {frequency : frequency},
            success : function(data) {
                //TODO : Add some message here.
            }
        });
        return false;
    });

    $(document).on("click","div.alerts_details table tr:gt(0)",function() {
        index = $(this).index() - 1;
        targetId = $(this).attr('rel');
        targetType = $(this).find('td:eq(0)').text();
        targetText = $(this).find('td:eq(1)').text();
        $("div.alerts_details table tr.active").removeClass('active');
        $(this).addClass('active');
        if (targetType != "Person")
            showSimilarCompanyBox(targetId,targetType,targetText,index);
        else
            hideSimilarCompanyBox();
    });

    $(document).on("click","a.add-similar-alert",function() {
        targetText = $(this).text();
        similarTargetId = $(this).parents().find('div.display_alertbox').attr('id');
        addSimilarAlert(targetText,similarTargetId);
        return false;
    });

    // select element styling
    initialiseSelectBox();

    /***********************************************************************************************************************
     *
     *  Responsive layout helpers starts here
     *
     **********************************************************************************************************************/

    $("div.mobile-top-menu").click(function() {
        $('ul.menu-list-box').show();
        $('div.mobile-top-menu').removeClass('mobile-top-normal');
        $('div.mobile-top-menu').addClass('mobile-top-hover');
    });

    $(document).mouseup(function (e)
    {
        var container = $("div.mobile-top-menu");
        if (container.has(e.target).length === 0)
        {
            $('ul.menu-list-box').hide();
            $('div.mobile-top-menu').removeClass('mobile-top-hover');
            $('div.mobile-top-menu').addClass('mobile-top-normal');
        }
    });

    /***********************************************************************************************************************
     *
     *  Responsive layout helpers ends here
     *
     **********************************************************************************************************************/
});

/***********************************************************************************************************************
 *
 *  Document on load ends here
 *
 **********************************************************************************************************************/

function requestAutoComplete() {
    $(".request_connection_search").autocomplete({
        source: function( request, response ) {
            company = $('input[name="title"]').last().val();
            query = $('input[name="query"]').last().val();
            var url,data = null;
            url = getPeopleInCompanyUrl;
            data = {
                company: company,
                query: query
            }
            $.ajax({
                url: url,
                data: data,
                success: function( data ) {
                    if(data.error == null && typeof data.error != "undefined") {
                        $('div.search-connection-no-result').hide();
                        $('.autocomplete-box table tbody').html("");
                        persons = data.person;
                        for (var i=0;i<persons.length;i++) {
                            pictureUrl = persons[i]["picture-url"];
                            headline = persons[i]["headline"];
                            linkedinId = persons[i]["id"];
                            firstName = "";
                            lastName = "";
                            name = "";
                            if(!pictureUrl)
                                pictureUrl = "/assets/user_photo.jpg";
                            if(persons[i]["first-name"]) {
                                name = persons[i]["first-name"];
                                firstName = persons[i]["first-name"];
                            }
                            if(persons[i]["last-name"]){
                                name = name + " " + persons[i]["last-name"];
                                lastName = persons[i]["last-name"];
                            }
                            if((name + headline).length > 51) {
                                headline = headline.substring(0,(51 - name.length - 2)) + "..."
                            }
                            $('.autocomplete-box table tbody').last().append('<tr><td width="6%" ><img class="photo" src="' + pictureUrl + '" alt="" title="" /></td><td><span class="col-blue font-16 calibrib">' + name + '</span><span> ' + headline + '</span><p class="display-none">' + linkedinId + '</p><p class="display-none">' + firstName + '</p><p class="display-none">' + lastName + '</p></td></tr>')
                        };
                        $('div.search-connection-loader').hide();
                    }
                    else {
                        $('div.search-connection-no-result').show();
                        $('.search-connection-loader').hide();
                    }
                }
            })
        },
        minLength: 4,
        delay: 2000,
        autoFocus: true,
        search: function( event, ui ) {
//            $('.autocomplete-box table tbody').html("");
//            $('.search-connection-loader').show();
//            $('.autocomplete-box').show();
        },
        change: function( event, ui ) {
//            if($('.request_connection_search').last().val().length < 3) {
//                $('.autocomplete-box').fadeOut();
//            }
        }
    });
}

function searchPeopleForQuery() {
    $(".request_connection_search").autocomplete({
        source: function( request, response ) {
            var url,data, alertBox = null;
            query = $('input[name="query"]').last().val();
            if(query == "") {
                query = $('input.request_connection_search:focus').val();
                alertBox = true;
            }
            url = getPersonsForQueryUrl;
            data = {
                query: query
            }
            $.ajax({
                url: url,
                data: data,
                success: function( data ) {
                    if(data.error == null && typeof data.error != "undefined" && data.person != null) {
                        $('div.search-connection-no-result').hide();
                        $('.autocomplete-box table tbody').html("");
                        persons = data.person;
                        for (var i=0;i<persons.length;i++) {
                            pictureUrl = persons[i]["picture-url"];
                            headline = persons[i]["headline"];
                            linkedinId = persons[i]["id"];
                            firstName = "";
                            lastName = "";
                            name = "";
                            if(!pictureUrl)
                                pictureUrl = "/assets/user_photo.jpg";
                            if(persons[i]["first-name"]) {
                                name = persons[i]["first-name"];
                                firstName = persons[i]["first-name"];
                            }
                            if(persons[i]["last-name"]){
                                name = name + " " + persons[i]["last-name"];
                                lastName = persons[i]["last-name"];
                            }
                            if(((name + headline).length > 51) && alertBox) {
                                headline = headline.substring(0,(51 - name.length - 2)) + "..."
                            }
                            else if((name + headline).length > 51) {
                                headline = headline.substring(0,(51 - name.length - 2)) + "..."
                            }
                            $('.autocomplete-box table tbody:visible').last().append('<tr><td width="6%" ><img class="photo" style="width: 25px;height: 25px;" src="' + pictureUrl + '" alt="" title="" /></td><td><span class="col-blue font-16 calibrib">' + name + '</span><span> ' + headline + '</span><p class="display-none">' + linkedinId + '</p><p class="display-none">' + firstName + '</p><p class="display-none">' + lastName + '</p></td></tr>')
                        }
                        $('div.search-connection-loader').hide();
                    }
                    else {
                        $('div.search-connection-no-result').show();
                        $('.search-connection-loader').hide();
                    }
                }
            })
        },
        minLength: 4,
        delay: 2000,
        autoFocus: true,
        search: function( event, ui ) {
//            $('.autocomplete-box table tbody').html("");
//            $('.search-connection-loader').show();
//            $('.autocomplete-box').show();
        },
        change: function( event, ui ) {
//            if($('.request_connection_search').last().val().length < 3) {
//                $('.autocomplete-box').fadeOut();
//            }
        }
    });
}

function searchGroup() {
    var query = $('input[name="group"]').last().val();
    var url = searchGroupForQueryUrl;
    var data = {
        query: query
    }
    $.ajax({
        url: url,
        data: data,
        type: "POST",
        success: function( data ) {
            if(data.error == null && typeof data.error != "undefined") {
                $('.group-autocomplete-box table tbody').last().html("");
                tags = data.tagDetail;
                if(tags && typeof tags != "undefined") {
                    for (var i=0;i<tags.length;i++) {
                        tagId = tags[i]["tagId"];
                        tagName = tags[i]["tagName"];
                        isAlreadyMemberInTag = tags[i]["isAlreadyMemberInTag"]
                        $('.group-autocomplete-box table tbody').last().append('<tr><td width="6%" ><img class="photo" src="/assets/user_photo.jpg" alt="" title="" /></td><td>' + tagName + '</td><input type="hidden" value="' + tagId + '" rel="' + isAlreadyMemberInTag + '"/> </tr>');
                    };
                    $('.search-group-no-result').last().hide();
                    $('.group-autocomplete-box').last().show();
                }
                else {
                    $('div.group-autocomplete-box').last().hide();
                    $('div.group-not-exist').last().show();
                }
            }
            else {
                $('div.group-autocomplete-box').last().hide();
                $('div.group-not-exist').last().show();
            }
            $('.search-group-info').last().hide();
            $('.search-group-loader').last().hide();
            $.colorbox.resize();
        }
    });
}

function searchGroupMembers() {
    $(".admin-search").autocomplete({
        source: function( request, response ) {
            $('div.search-connection-no-result').hide();
            $('.admin-autocomplete-box table tbody').html("");
            var query = $('input[name="member"]').last().val();
            var tagID = $('input[name="tag_id"]').last().val();
            var url = searchMemberInGroupUrl;
            var data = {
                query: query,
                tagID: tagID
            }
            $.ajax({
                url: url,
                data: data,
                type: "POST",
                success: function( data ) {
                    if(data.error == null && typeof data.error != "undefined") {
                        $('.admin-autocomplete-box table tbody').html("");
                        groupUsers = data.groupUser;
                        if(groupUsers && typeof groupUsers != "undefined") {
                            for (var i=0;i<groupUsers.length;i++) {
                                userId = groupUsers[i]["userId"];
                                firstName = "";
                                lastName = "";
                                name = "";
                                if(groupUsers[i]["firstName"]) {
                                    name = groupUsers[i]["firstName"];
                                }
                                if(groupUsers[i]["lastName"]){
                                    name = name + " " + groupUsers[i]["lastName"];
                                }
                                $('.admin-autocomplete-box table tbody').last().append('<tr><td width="6%" ><img class="photo" src="/assets/user_photo.jpg" alt="" title="" /></td><td>' + name + '</td><input type="hidden" value="' + userId + '"/> </tr>');
                            };
                            $('div.search-connection-loader').hide();
                        }
                        else {
                            $('div.search-connection-no-result').show();
                            $('.search-connection-loader').hide();
                        }
                    }
                    $.colorbox.resize();
                }
            });
        },
        minLength: 4,
        delay: 2000,
        autoFocus: true,
        search: function( event, ui ) {
        },
        change: function( event, ui ) {
        }
    });
}

function getPeopleList() {
    console.log("Initializing person autocomplete");
    $('input[name="person-name"]').autocomplete({
        source: function( request, response ) {
            $.ajax({
                url: getPersonsForQueryUrl,
                data: {
                    query: request.term
                },
                success: function( data ) {
                    if(data.error == null && typeof data.error != "undefined" && data.person != null) {
                        $('div.search-connection-no-result').hide();
                        $('.person-autocomplete-box table tbody').html("");
                        persons = data.person;
                        if(persons) {
                            for (var i=0;i<persons.length;i++) {
                                pictureUrl = persons[i]["picture-url"];
                                headline = persons[i]["headline"];
                                linkedinId = persons[i]["id"];
                                firstName = "";
                                lastName = "";
                                name = "";
                                if(!pictureUrl)
                                    pictureUrl = "/assets/user_photo.jpg";
                                if(persons[i]["first-name"]) {
                                    name = persons[i]["first-name"];
                                    firstName = persons[i]["first-name"];
                                }
                                if(persons[i]["last-name"]){
                                    name = name + " " + persons[i]["last-name"];
                                    lastName = persons[i]["last-name"];
                                }
                                else if((name + headline).length > 51) {
                                    headline = headline.substring(0,(51 - name.length - 2)) + "..."
                                }
                                $('.person-autocomplete-box table tbody').append('<tr><td width="6%" ><img class="photo" style="width: 25px;height: 25px;" src="' + pictureUrl + '" alt="" title="" /></td><td><span class="col-blue font-16 calibrib">' + name + '</span><span> ' + headline + '</span><p class="display-none">' + linkedinId + '</p><p class="display-none">' + firstName + '</p><p class="display-none">' + lastName + '</p></td></tr>')
                            }
                            $('div.search-connection-loader').hide();
                        }
                        else {
                            $('div.search-connection-no-result').show();
                            $('.search-connection-loader').hide();
                        }
                    }
                    else {
                    }
                }
            })
        },
        minLength: 4,
        delay: 2000,
        autoFocus: true,
        search: function( event, ui ) {},
        change: function( event, ui ) {}
    });
}

function getIndustryList() {
    console.log("Initializing industry autocomplete");
    $('input[name="industries"]').autocomplete({
        source: function( request, response ) {
            var inputElement = $('input[name="industries"]');
            var noResultElement = inputElement.parent('span').next('div.listboxs').find('div.search-connection-no-result').show();
            var listContainer = inputElement.parent('span').next('div.listboxs').find('ul');
            var listContainerParent = inputElement.parent('span').next('div.listboxs');
            var loader = $('div.search-connection-loader');
            listContainer.html("");
            listContainer.hide();
            noResultElement.hide();
            loader.show();
            $.ajax({
                url: searchIndustriesUrl,
                data: {
                    query: request.term
                },
                success: function( data ) {
                    if(data.error == null && typeof data.error != "undefined") {
                        industries = data.industry;
                        if(industries) {
                            for (var i=0;i<industries.length;i++) {
                                listContainer.append('<li class="add-alert-industry" style="cursor: pointer;">' + industries[i].industryType + '</li>')
                            }
                            listContainer.show();
                        }
                        else {
                            noResultElement.show();
                        }
                    }
                    else {
                        noResultElement.show();
                    }
                    loader.hide();
                    listContainerParent.show();
                }
            })
        },
        minLength: 4,
        delay: 2000,
        autoFocus: true,
        search: function( event, ui ) { },
        change: function( event, ui ) { }
    });
}

function getLocationList() {
    console.log("Initializing location autocomplete");
    $('input[name="locations"]').autocomplete({
        source: function( request, response ) {
            var inputElement = $('input[name="locations"]');
            var noResultElement = inputElement.parent('span').next('div.listboxs').find('div.search-connection-no-result').show();
            var listContainer = inputElement.parent('span').next('div.listboxs').find('ul');
            var listContainerParent = inputElement.parent('span').next('div.listboxs');
            var loader = $('div.search-connection-loader');
            listContainer.html("");
            listContainer.hide();
            noResultElement.hide();
            loader.show();
            $.ajax({
                url: searchLocationsUrl,
                data: {
                    query: request.term
                },
                success: function( data ) {
                    if(data.error == null && typeof data.error != "undefined") {
                        locations = data.locations;
                        if(locations) {
                            for (var i=0;i<locations.length;i++) {
                                listContainer.append('<li class="add-alert-location" style="cursor: pointer;">' + locations[i].state + '</li>')
                            }
                            listContainer.show();
                        }
                        else {
                            noResultElement.show();
                        }
                    }
                    else {
                        noResultElement.show();
                    }
                    loader.hide();
                    listContainerParent.show();
                }
            })
        },
        minLength: 4,
        delay: 2000,
        autoFocus: true,
        search: function( event, ui ) { },
        change: function( event, ui ) { }
    });
}

function adjustTooltip() {
    var toolTip = $(".tooltip-box");
    var toolTipHeight = toolTip.height();
    if (toolTipHeight < 131) {
        var diff  =  130 - toolTipHeight;
        var diffTop = -100 + diff
        toolTip.css('top', diffTop);
    } else if ( toolTipHeight >= 132){
        var diff  =  toolTipHeight - 130;
        var diffTop = -100 - diff;
        diffTop = diffTop < -145 ? -145 : diffTop;
        toolTip.css('top', diffTop);
    }
}

function adjustTooltip2() {
    var toolTip = $(".tooltip-box");
    var toolTipHeight = toolTip.height();
    if (toolTipHeight < 131) {
        var diff  =  130 - toolTipHeight;
        var diffTop = -50 + diff
        toolTip.css('top', diffTop);
    } else if ( toolTipHeight >= 132){
        var diff  =  toolTipHeight - 130;
        var diffTop = -50 - diff;
        diffTop = diffTop < -145 ? -145 : diffTop;
        toolTip.css('top', diffTop);
    }
}

function adjustAddAdminLink() {
    adminNames = $('span#admin-box a');
    len = 0;
    for(i=0;i<adminNames.length;i++) {
        len = len + $(adminNames[i]).html().length;
    }
    headingWidth = $('#heading-width').width();
    adminWidth = $('#admin-width').width();
    totalWidth = $('#admin-box').width();
    padding = 4;
    remainingWidth = (headingWidth + adminWidth + padding) - totalWidth;
    if(len < 50 && remainingWidth < 0) {
        $('a#add-admin').css('margin-left',remainingWidth + 'px')
    }
}

function showImagePreview(files) {
    if( typeof files != "undefined") {
        file = files[0];
        var reader = new FileReader();
        reader.onloadend = function(e) {
            $('img.upload-image-preview-box').last().attr('src', e.target.result);
            $('div.upload-logo-box').last().hide();
            $('img.upload-image-preview-box').last().show();
        };
        reader.readAsDataURL(file);
    }
}

function addCsvFile(files) {
    $('a.add-csv-file').last().hide();
    $('input.upload-csv-input').last().show();
    $.colorbox.resize();
}

function addAlertCsvFile(files) {
    $('a.alert-csv-file').last().hide();
    $('input.alert-csv-submit').last().show();
    $.colorbox.resize();  1
}

function applyOnlyCompanyConnectionsFilter() {
    if ($('input#only-company-filter').is(':checked')) {
        $('span.filter_column input.text_filter').last().val(gCompanyMembersName);
        $('span.filter_column input.text_filter').last().trigger('keyup');
    } else {
        $('span.filter_column input.text_filter').last().val("");
        $('span.filter_column input.text_filter').last().trigger('keyup');
    }
    selectedCompany = $('input:checked[name=company-radio]').val();
    $('tr.all-companies').hide();
    $('tr.show-more-company-results').hide();
    $("tr[class*='" + selectedCompany + "']").show();
}

function applySearchAlertsFilter(searchInput) {
    query = $(searchInput).val();
    $('div.search-box input.filter-input').val(query);
    $('div.search-box input.filter-input').trigger('keyup');
}

function userTagsFocus(e) {
    if(e.target.className == "mygroups-dbox col-blue")
        window.location.href = userProfilePath;
}

function markConnectedToSalesForce(form){
    $(form).find('input[name=contactsIdJson]').val(JSON.stringify(gConnectedSalesForce));
    $(form).submit();
}

function initialiseSelectBox() {
    $('select.select:visible').each(function(){
        var title = $(this).attr('title');
        if($('option:selected', this).val() != '')
            title = $('option:selected',this).val();
        if($(this).next('span').length == 0)
            $(this)
                .css({'z-index':10,'opacity':0,'-khtml-appearance':'none'})
                .after('<span class="select">' + title + '</span>')
                .change(function(){
                    val = $('option:selected',this).val();
                    $(this).next().text(val);
                });
        else
            $(this)
                .css({'z-index':10,'opacity':0,'-khtml-appearance':'none'})
                .change(function(){
                    val = $('option:selected',this).val();
                    $(this).next().text(val);
                });
    });
}

function initializeRecipientAutoComplete(refObject) {
    console.log("Initializing searchPeopleForQuery()");
    searchPeopleForQuery();
    $(refObject).parents('.ofunnel-alerts').find('.autocomplete-box:visible').hide();

    if($(refObject).parents('.ofunnel-alerts').find('select').val() == 'Person') {
        $(refObject).parents('.ofunnel-alerts').find('input.normal:visible').hide();
        $(refObject).parents('.ofunnel-alerts').find('input.person').show();
        $(refObject).parents('.ofunnel-alerts').find('a.person-downarrow').show();
    }
    else {
        $(refObject).parents('.ofunnel-alerts').find('input.normal').show();
        $(refObject).parents('.ofunnel-alerts').find('input.person').hide();
        $(refObject).parents('.ofunnel-alerts').find('a.person-downarrow:visible').hide();
    }
}

function resetAutocomplete(inputElement) {
    var noResultElement = inputElement.parent('span').next('div.listboxs').find('div.search-connection-no-result').show();
    var listContainer = inputElement.parent('span').next('div.listboxs').find('ul');
    var listContainerParent = inputElement.parent('span').next('div.listboxs');
    var loader = $('div.search-connection-loader');
    inputElement.val("");
    listContainer.html("");
    listContainer.hide();
    noResultElement.hide();
    loader.show();
    listContainerParent.hide();
}

function setIndustryList() {
    $('span.industry').each(function() {
        selected = $(this).text();
        checkbox = $('input[value="' + $(this).text()  + '"]');
        rel =  checkbox.attr('rel');
        $(this).find('a').attr('rel',rel);
        checkbox.prop('checked',true).parents('li').addClass('selected2');
    });
}

function setLocationList() {
    $('span.location').each(function() {
        selected = $(this).text();
        checkbox = $('input[value="' + $(this).text()  + '"]');
        id =  checkbox.attr('rel');
        $(this).find('a').attr('rel',id);
        checkbox.prop('checked',true).parents('li').addClass('selected2');
    });
}

function addRoleFilter(roleInput) {
    value = $(roleInput).val();
    if(value.match(/\S/)) {
        $(roleInput).parents('div.pos-Rel').before('<span class="role darkgray mrg-L5 mrg-T5">' +
            value + '<a class="remove-darkgray" href="#">' +
            '<img src="/assets/close.png" width="8" height="8" alt="close">' +
            '</a></span>');
        $('input[name="role2"]').attr('placeholder','').attr('onblur',"this.placeholder = ''");
        $(roleInput).val("");
    }
}

function addCompanyFilter(companyInput) {
    value = $(companyInput).val();
    if(value.match(/\S/)) {
        $(companyInput).parents('div.pos-Rel').before('<span class="company darkgray mrg-L5 mrg-T5">' +
            value + '<a class="remove-darkgray" href="#">' +
            '<img src="/assets/close.png" width="8" height="8" alt="close">' +
            '</a></span>');
        $('input[name="company2"]').attr('placeholder','').attr('onblur',"this.placeholder = ''");
        $(companyInput).val("");
    }
}

function payBoradLoginEvent() {
    Payboard.Events.setApiKey('494dc013-d0b4-4f25-a787-89c05f27ea27');
    var event = {
        customerId: userId,
        customerName: userName,
        CustomerUserId: userId,
        CustomerUserFirstName: userFirstName,
        CustomerUserLastName: userLastName,
        customerUserEmail: userEmail,
        eventName: 'LoggedIn'
    };
    Payboard.Events.trackCustomerUserEvent(event);
}

function payBoardNewAlertEvent() {
    Payboard.Events.setApiKey('494dc013-d0b4-4f25-a787-89c05f27ea27');
    var event = {
        customerId: userId,
        customerName: userName,
        CustomerUserId: userId,
        CustomerUserFirstName: userFirstName,
        CustomerUserLastName: userLastName,
        customerUserEmail: userEmail,
        eventName: 'New Alert Added'
    };
    Payboard.Events.trackCustomerUserEvent(event);
}

function addSimilarAlert(targetText,similarTargetId) {
    $.ajax({
        url: addSimilarAlertUrl,
        type: "POST",
        data: {
            similarTargetId: similarTargetId,
            targetText: targetText
        },
        success: function( data ) {
            alertToAppendTo = $("tr[rel=" + similarTargetId + "]");
            alertToAppendTo.after((data));
        }
    });
}

function showSimilarCompanyBox(targetId,targetType,targetText,index) {
    hideSimilarCompanyBox();
    if (targetType == "Company") {
        url = similarCompaniesUrl;
    }
    else if (targetType == "Role") {
        url = similarRolesUrl;
    }
    $.ajax({
        url: url,
        type: "POST",
        data: {
            targetId: targetId,
            targetType: targetType,
            targetText: targetText
        },
        success: function( data ) {
            $('.display_alertbox').replaceWith(data);
            adjustSimilarBox(index);
        }
    });
}

function hideSimilarCompanyBox() {
    $('.display_alertbox').hide();
}

function adjustSimilarBox(index) {
    marginTop =  index > 0 ? (
        (50 + index * 41) + "px"
        ) : "50px";
    $(".display_alertbox").css("margin-top",marginTop);
}

jQuery.fn.exists = function(){
    return this.length>0;
}

jQuery.fn.toggleText = function (value1, value2) {
    return this.each(function () {
        var $this = $(this),
            text = $this.text();

        if (text.indexOf(value1) > -1)
            $this.text(text.replace(value1, value2));
        else
            $this.text(text.replace(value2, value1));
    });
};
