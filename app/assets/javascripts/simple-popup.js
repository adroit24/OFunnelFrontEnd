// JavaScript Document

function toggle(div_id) {
	var el = document.getElementById(div_id);
	if ( el.style.display == 'none' ) {	el.style.display = 'block';}
	else {el.style.display = 'none';}
}
function black_overlay_size(popUpDivVar) {
	if (typeof window.innerWidth != 'undefined') {
		viewportheight = window.innerHeight;
	} else {
		viewportheight = document.documentElement.clientHeight;
	}
	if ((viewportheight > document.body.parentNode.scrollHeight) && (viewportheight > document.body.parentNode.clientHeight)) {
		black_overlay_height = viewportheight;
	} else {
		if (document.body.parentNode.clientHeight > document.body.parentNode.scrollHeight) {
			black_overlay_height = document.body.parentNode.clientHeight;
		} else {
			black_overlay_height = document.body.parentNode.scrollHeight;
		}
	}
	var black_overlay = document.getElementById('black_overlay');
	black_overlay.style.height = black_overlay_height + 'px';
	var popUpDiv = document.getElementById(popUpDivVar);
	popUpDiv_height = viewportheight/2-235;//100 is half popup's height
	popUpDiv.style.top = popUpDiv_height + 'px';
}
function window_pos(popUpDivVar) {
	if (typeof window.innerWidth != 'undefined') {
		viewportwidth = window.innerWidth;
	} else {
		viewportwidth = document.documentElement.clientWidth;
	}
	if ((viewportwidth > document.body.parentNode.scrollWidth) && (viewportwidth > document.body.parentNode.clientWidth)) {
		window_width = viewportwidth;
	} else {
		if (document.body.parentNode.clientWidth > document.body.parentNode.scrollWidth) {
			window_width = document.body.parentNode.clientWidth;
		} else {
			window_width = document.body.parentNode.scrollWidth;
		}
	}
	var popUpDiv = document.getElementById(popUpDivVar);
	window_width = viewportwidth/2-345;//250 is half popup's width
	popUpDiv.style.left = window_width + 'px';
}
function popup(windowname) {
	black_overlay_size(windowname);
	window_pos(windowname);
	toggle('black_overlay');
	toggle(windowname);		
}
