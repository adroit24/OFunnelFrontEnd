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
    if(typeof hootSuiteEnabled != "undefined" && hootSuiteEnabled) {
        hsp.init(
            {
                apiKey: '0u1agem6ryyowc8wccs8o8wc43iaa9afcml',
                receiverPath: hootsuiteRecieverPath,
                useTheme: true,
                subtitle: '(' + hootsuiteUserName + ')',
                callBack: function( message ){
                    console.log('Error: ' + message);
                }
            }
        );

        hsp.bind('refresh', function() {
            if($(window).scrollTop() < 150) {
                window.location.reload();
            }
        });

        $(window).scroll(bindScroll);
    }

    $('span.topsec_dropdown').click(function() {
        $('div.top_links').toggle();
    });
});

function loadMore() {
    console.log("More loaded");
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
