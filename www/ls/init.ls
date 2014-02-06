window.ig =
    projectName : "sochi-asl"
    containers: {}

_gaq?.push(['_trackEvent', 'ig', ig.projectName]);

anchors = document.querySelectorAll "*[data-ig]"
for anchor in anchors
    content = anchor.getAttribute \data-ig
    div = document.createElement \div
        ..className = "ig #{ig.projectName} #{content}"

    parent = anchor.parentElement
    parent.replaceChild div, anchor
    ig.containers[content] = div
