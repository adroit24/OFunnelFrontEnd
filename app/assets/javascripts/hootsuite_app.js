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
                        console.log('Error: ' + message);
                    }
                }
            );

            console.log("Binding hsp refresh");
            hsp.bind('refresh', function() {
                if($(window).scrollTop() < 150) {
                    window.location.reload();
                }
            });

            $(window).scroll(bindScroll);
        }
    }

    $('span.topsec_dropdown').click(function() {
        $('div.settings_links').hide();
        $('div.top_links').toggle();
    });

    $('span.topsec_settings').click(function() {
        $('div.top_links').hide();
        $('div.settings_links').toggle();
    });

    $(document).on('click','a.alert-remove-target',function(){
        removePath = $(this).attr('href');
        type = $(this).prevAll('div').find('select.alert-type').val();
        name = $(this).prevAll('div.input-relative2').find("input.name-select:visible").val();
        alertId = $(this).prevAll('input[name=alertId]').val();
        elementToRemove = $(this).parents('div.ofunnel-alerts');
        if(alertId === "" || name == "") {
            elementToRemove.remove();
        }
        else {
            $.ajax({
                type : 'POST',
                url : removePath,
                data : {type:type,name:name,alertId:alertId,dataType : "json"},
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
                name = $(this).find('input.name-select:visible').val();
                alertId = $(this).find('input[name=alertId]').val();
                if(type != "" && name != "")
                    alertJson.push({
                        "type" : type,
                        "name" : name,
                        "alertId" : alertId
                    });
            });
//            $.ajax({
//                type : 'POST',
//                url : $(this).attr('action'),
//                data : $(this).serialize(),
//                dataType: 'jsonp',
//                contentType: 'application/json',
//                processData: false,
//                xhrFields: {
//                    withCredentials: true
//                },
//                crossDomain: true,
//                success : function(data) {
//                    if(data.error == null && typeof data.error != "undefined") {
//                        $('div#alert-target-account-added').show();
//                    }
//                }
//            });
            $('input[name=alertJson]').val(JSON.stringify(alertJson));
            $('div#alert-target-account-error').hide();
        }
    });
});

/*************************************************
 *
 * Document.ready() ends here
 *
 *************************************************/

function loadMore() {
    if(activeTab == "stream") {
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
                    eventTime = new Date(value.updatedAt).strftime("%b %e, %I:%M%P");
                    $("div.alert-wrapper").last().append(
                        '<div class="alert-wrapper">' +
                            '<div class="' + hootsuiteTheme + '">' +
                            '<div class="thumbtop_section">' +
                            '<div class="height10"></div>' +
                            '<div class="target_block">Target ' + capitaliseFirstLetter(alertType) + ': ' + networkAlert + '</div>' +
                            '<div class="thimg"><div class="thumb_img"><a href="#"><img src="' + profilePic + '"  alt="img" style="height: 30px;width: 30px;"></a></div></div>' +
                            '<div class="thumbuser_details">' +
                            '<p class="thumb_username"><a href="' + value.yourConnectionProfileUrl + '"' + target + '>' + value.yourConnectionFirstName + " " + value.yourConnectionLastName + '</a></p>' +
                            '<div class="thumb_date">' + eventTime + '</div>' +
                            '<p class="text"><a href="' + value.yourConnectionProfileUrl + '"' + target + '>' + value.yourConnectionFirstName + " " + value.yourConnectionLastName + '</a> is now connected to <a href="' + value.connectedToProfileUrl + '"' + fTarget + '>' + value.connectedToFirstName + ' ' + value.connectedToLastName + '</a></p>' +
                            '</div>' +
                            '<div class="bigimg_details">' +
                            '<div class="large_img"><a href="#"><img src="' + fProfilePic + '" alt="img"></a></div>' +
                            '<div class="bigbuser_details">' +
                            '<p class="bigbuser_username"><a href="' + value.connectedToProfileUrl + '"' + fTarget + '>' + value.connectedToFirstName + ' ' + value.connectedToLastName + '</a></p>' +
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
                $.each( data.alert, function( index, value ){
                    $("div.alert-details").last().append(
                        '<div class="addmore-box ofunnel-alerts">' +
                            '<div class="input-relative comp-select">' +
                            '<div class="select-box">' +
                            '<select class="select alert-type" title="">' +
                            '<option' + ((value.type == "COMPANY") ? " selected=true" : "") + '>Company</option>' +
                            '<option' + ((value.type == "PERSON") ? " selected=true" : "") + '>Person</option>' +
                            '<option' + ((value.type == "ROLE") ? " selected=true" : "") + '>Role</option>' +
                            '</select></div></div>' +
                            '<input type="text" name="name" class="name-select" value="' + value.name + '" Placeholder="Nike" />' +
                            '<input type="hidden" name="alertId" value="' + value.alertId + '" />' +
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

