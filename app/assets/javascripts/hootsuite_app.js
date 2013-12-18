/**
 * Created with JetBrains RubyMine.
 * User: udit
 * Date: 1/10/13
 * Time: 2:29 PM
 * To change this template use File | Settings | File Templates.
 */

// if params[:controller] == "hootsuite"
//= require jquery
// end

$( document ).ready(function() {

    if(typeof trackLoginEvent != "undefined" && trackLoginEvent && typeof hootsuiteEnabled != "undefined" && hootsuiteEnabled)
        payBoradLoginEvent();

    if(typeof trackAlertEvent != "undefined" && trackAlertEvent && typeof hootsuiteEnabled != "undefined" && hootsuiteEnabled)
        payBoardNewAlertEvent();

    if(typeof hootsuiteEnabled != "undefined" && hootsuiteEnabled) {
        if(hootsuiteAppInit) {
            console.log("Initializing HootSuite SDK");
            hsp.init(
                {
                    apiKey: hootsuiteAppKey,
                    receiverPath: hootsuiteRecieverPath,
                    useTheme: true,
                    subtitle: '(' + hootsuiteUserName + ')',
                    callBack: function( message ){
                        console.log('OFunnel: ' + message);
                    }
                }
            );

            console.log("Binding hsp refresh");
            hsp.bind('refresh', function() {
                hsReload = true;
                hsScrollTop = $(window).scrollTop();
                if(hsScrollTop > 150) {
                    hsReload = false;
                }
                else if($("input:focus").length > 1) {
                    hsReload = false;
                }

                if(hsReload) {
                    window.location.reload();
                }
                else {
                    console.log("Suppressing hsp refresh");
                }
            });

            $(window).scroll(bindScroll);
        }

        $('.hs_topBar .hs_controls a').click(function(e) {
            var $control = $(this),
                $dropdown = $('.hs_topBar .hs_dropdown');
            $dropdown.children().hide();
            if ($control.attr('dropdown').length) {
                $dropdown.children('.' + $control.attr('dropdown')).show();
            }
            if($dropdown.is(':visible') && $control.hasClass('active')) {
                $dropdown.hide();
            } else {
                $dropdown.show();
            }
            $control.siblings('.active').removeClass('active');
            $control.toggleClass('active');

            e.preventDefault();
        });

        $(document).on('click','a.alert-remove-target',function(){
            removePath = $(this).attr('href');
            type = $(this).prevAll('div').find('select.alert-type').val();
            alertName = $(this).prevAll("input.name-select:visible").val();
            alertId = $(this).prevAll('input[name=alertId]').val();
            elementToRemove = $(this).parents('div.ofunnel-alerts');
            if(!(alertId && name)) {
                elementToRemove.remove();
            }
            else {
                $.ajax({
                    type : 'POST',
                    url : removePath,
                    data : {type:"type",name:alertName,alertId:alertId,dataType : "json"},
                    dataType: 'jsonp',
                    xhrFields: {
                        withCredentials: true
                    },
                    crossDomain: true,
                    success : function(data) {
                        if(data.error == null && typeof data.error != "undefined") {
                            elementToRemove.remove();
                        }
                    }
                });
            }
            return false;
        });

        $(document).on('click','a.hs-open-user-info-popup',function(){
            linkedInID = $(this).attr("rel");
            $.ajax({
                type : 'POST',
                url : getLinkedInProfileUrl,
                data : {linkedin_id:linkedInID,dataType : "json"},
                dataType: 'jsonp',
                xhrFields: {
                    withCredentials: true
                },
                crossDomain: true,
                success : function(data) {
                    if(typeof data.error == "undefined") {
                        fullName = data.firstName + ' ' + data.lastName;
                        profileUrl = data.publicProfileUrl;
                        profilePicUrl = data.pictureUrl;
                        headline = data.headline;
                        userLocation = data.location.name;
                        industry = data.positions.values[0].company.industry;
                        hsp.customUserInfo({
                            "fullName": fullName,
                            "avatar": profilePicUrl,
                            "extra": [
                                { "label": "Headline", "value": headline },
                                { "label": "Location", "value": userLocation },
                                { "label": "Industry", "value": industry }
                            ],
                            "links": [
                                { "label": "Profile", "url": profileUrl }
                            ]
                        });
                    }
                }
            });
            return false;
        });

        $(document).on('click','a#alert-add-target-account',function(){
            if($('input[name=name]:visible').first().val() != "") {
                $('div.alert-details').prepend($('div.extra-alert-container').html());
            }
            $('input.name-select:visible').first().focus();
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
                $('div#alert-target-account-error').show();
                return false;
            }
            else {
                alertJson = [];
                targetAlerts.each(function() {
                    type = $(this).find('select.alert-type').val();
                    alertName = $(this).find('input.name-select:visible').val();
                    alertId = $(this).find('input[name=alertId]').val();
                    if(type != "" && name != "")
                        alertJson.push({
                            "type" : type,
                            "name" : alertName,
                            "alertId" : alertId
                        });
                });
                $.ajax({
                    type : 'POST',
                    url : $(this).attr('action'),
                    data : {alertJson:JSON.stringify(alertJson)},
                    dataType: 'json',
                    xhrFields: {
                        withCredentials: true
                    },
                    crossDomain: true,
                    success : function(data) {
                        if(data.error == null && typeof data.error != "undefined") {
                            $('div#alert-target-account-added span').text("Target accounts has been added");
                            $('div#alert-target-account-added').fadeIn();
                            payBoardNewAlertEvent();
                        }
                        else {
                            $('div#alert-target-account-added span').text("Error occurred, please try again");
                            $('div#alert-target-account-added span').fadeIn();
                        }
                        $('#alert-target-account-added').delay('3000').fadeOut();
                    }
                });
                $('div#alert-target-account-error').hide();
            }
            return false;
        });
    }
});

/*************************************************
 *
 * Document.ready() ends here
 *
 *************************************************/

function loadMore() {
    if(activeTab == "ALERTS") {
        console.log("Loading more alerts");
        $.ajax({
            type: "POST",
            dataType: 'jsonp',
            data: {dataType : "json"},
            xhrFields: {
                withCredentials: true
            },
            crossDomain: true,
            url: hootsuiteStreamPath,
            success: function(data) {
                $.each( data, function( index, value ){
                    alertType = value.alertType;
                    networkAlert = value.targetName;
                    target = value.yourConnectionProfileUrl == "" ? '' : ' target="_blank"';
                    fTarget = value.connectedToProfileUrl == "" ? '' : ' target="_blank"';
                    profilePic = value.yourConnectionProfilePicUrl == "" ? "https://secure.ofunnel.com/assets/user_photo.jpg" : value.yourConnectionProfilePicUrl;
                    fProfilePic = value.connectedToProfilePicUrl == "" ? "https://secure.ofunnel.com/assets/user_photo.jpg" : value.connectedToProfilePicUrl;
                    linkedInId = value.yourConnectionLinkedInId;
                    fLinkedInId = value.connectedToLinkedInId;
                    eventTime = new Date(value.updatedAt).strftime("%b %e, %I:%M%P");
                    $("div.alert-wrapper").last().append(
                        '<div class="alert-wrapper">' +
                            '<div class="' + hootsuiteTheme + '">' +
                            '<div class="thumbtop_section">' +
                            '<div class="height10"></div>' +
                            '<div class="target_block">Target ' + capitaliseFirstLetter(alertType) + ': ' + networkAlert + '</div>' +
                            '<div class="thimg"><div class="thumb_img"><a class="hs-open-user-info-popup" href="#" rel="' + linkedInId + '"><img src="' + profilePic + '"  alt="img" style="height: 30px;width: 30px;"></a></div></div>' +
                            '<div class="thumbuser_details">' +
                            '<p class="thumb_username"><a class="hs-open-user-info-popup" href="#" rel="' + linkedInId + '">' + value.yourConnectionFirstName + " " + value.yourConnectionLastName + '</a></p>' +
                            '<div class="thumb_date">' + eventTime + '</div>' +
                            '<p class="text"><a class="hs-open-user-info-popup" href="#" rel="' + linkedInId + '">' + value.yourConnectionFirstName + " " + value.yourConnectionLastName + '</a> is now connected to <a class="hs-open-user-info-popup" href="#" rel="' + fLinkedInId + '">' + value.connectedToFirstName + ' ' + value.connectedToLastName + '</a></p>' +
                            '</div>' +
                            '<div class="bigimg_details">' +
                            '<div class="large_img"><a class="hs-open-user-info-popup" href="#" rel="' + fLinkedInId + '"><img src="' + fProfilePic + '" alt="img"></a></div>' +
                            '<div class="bigbuser_details">' +
                            '<p class="bigbuser_username"><a class="hs-open-user-info-popup" href="#" rel="' + fLinkedInId + '">' + value.connectedToFirstName + ' ' + value.connectedToLastName + '</a></p>' +
                            '<div class="biguser_designation">' +
                            '<p>' + value.connectedToHeadline + '</p>' +
                            '</div>' +
                            '</div>' +
                            '</div>' +
                            '<div class="height1"></div>' +
                            '</div>' +
                            '</div>' +
                            '</div>'
                    );
                });
                $(window).bind('scroll', bindScroll);
            }
        });
    }
    else {
        console.log("Loading more target accounts");
        $.ajax({
            type: "POST",
            dataType: 'jsonp',
            data: {dataType : "json"},
            xhrFields: {
                withCredentials: true
            },
            crossDomain: true,
            url: hootsuiteTargetPath,
            success: function(data) {
                $.each( data.targetAccount, function( index, value ){
                    $("div.alert-details").last().append(
                        '<div class="addmore-box ofunnel-alerts">' +
                            '<div class="input-relative comp-select">' +
                            '<div class="select-box">' +
                            '<select class="select alert-type" title="">' +
                            '<option' + ((value.filterType == "COMPANY") ? " selected=true" : "") + '>Company</option>' +
                            '<option' + ((value.filterType == "PERSON") ? " selected=true" : "") + '>Person</option>' +
                            '<option' + ((value.filterType == "ROLE") ? " selected=true" : "") + '>Role</option>' +
                            '</select></div></div>' +
                            '<input type="text" name="name" class="name-select" value="' + value.targetName + '" Placeholder="Nike" />' +
                            '<input type="hidden" name="alertId" value="' + value.targetAccountId + '" />' +
                            '<a href="' + hootsuiteRemoveRelationship + '" class="delete-icon alert-remove-target">' +
                            '</a></div>'
                    );
                });
                $(window).bind('scroll', bindScroll);
            }
        });
    }
}

function capitaliseFirstLetter(string)
{
    downString = string.toLowerCase();
    return downString.charAt(0).toUpperCase() + downString.slice(1);
}

function bindScroll(){
    if($(window).scrollTop() + $(window).height() > $(document).height() - 100) {
        $(window).unbind('scroll');
        loadMore();
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
