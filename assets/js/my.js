document.addEventListener("DOMContentLoaded",
(function(){
    var c = document.getElementById('logo');
    console.log(c);
    function addAnim() {
        c.classList.add('logo-animated')
        // remove the listener, no longer needed
        c.removeEventListener('mouseover', addAnim);
    };

    // listen to mouseover for the container
    c.addEventListener('mouseover', addAnim);
}));