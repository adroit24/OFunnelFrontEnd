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
});

function loadMore()
{
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
                target = value.yourConnectionProfileUrl == "" ? '' : ' target="_blank"'
                fTarget = value.connectedToProfileUrl == "" ? '' : ' target="_blank"'
                profilePic = value.yourConnectionProfilePicUrl == "" ? "https://secure.ofunnel.com/assets/user_photo.jpg" : value.yourConnectionProfilePicUrl
                fProfilePic = value.connectedToProfilePicUrl == "" ? "https://secure.ofunnel.com/assets/user_photo.jpg" : value.connectedToProfilePicUrl
                eventTime = new Date(value.updatedAt).strftime("%b %e, %I:%M%P")
                $("div.maincontainer").last().append(
                    '<div class="maincontainer">' +
                        '<div class="maincontainer_section">' +
                        '<div class="'+ hootsuiteTheme +'">' +
                        '<div class="thumbtop_section">' +
                        '<div class="thimg">' +
                        '<div class="thumb_img">' +
                        '<a href="#"><img src="' + profilePic + '" style="height: 100%;" alt="img"></a>' +
                        '</div></div>' +
                        '<div class="thumbuser_details">' +
                        '<p class="thumb_username"><a href="' + value.yourConnectionProfileUrl + '"' + target + '>' + value.yourConnectionFirstName + " " + value.yourConnectionLastName + '</a></p>' +
                        '<div class="thumb_date">' + eventTime + '</div>' +
                        '<p class="text"><a href="' + value.yourConnectionProfileUrl + '"' + target + '>' + value.yourConnectionFirstName + " " + value.yourConnectionLastName + '</a>' +
                        ' is now connected to ' +
                        '<a href="' + value.connectedToProfileUrl + '"' + value.fTarget + '>' + value.connectedToFirstName + ' ' + value.connectedToLastName + '</a></p>' +
                        '<div class="bigimg_details"><div class="large_img">' +
                        '<a href="#"><img src="' + fProfilePic + '" style="height: 100%;" alt="img"></a>' +
                        '</div>' +
                        '<div class="bigbuser_details"><p class="bigbuser_username">' +
                        '<a href="' + value.connectedToProfileUrl + '"' + value.fTarget + '>' + value.connectedToFirstName + ' ' + value.connectedToLastName + '</a>' +
                        '</p>' +
                        '<div class="biguser_designation">' + value.connectedToHeadline + '</div></div></div></div></div></div></div></div>'
                );
            });
            $(window).bind('scroll', bindScroll);
        }
    });
}

function bindScroll(){
    if($(window).scrollTop() + $(window).height() > $(document).height() - 100) {
        $(window).unbind('scroll');
        loadMore();
    }
}
