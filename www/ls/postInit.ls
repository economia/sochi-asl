style = document.createElement 'style'
    ..innerHTML = JSON.parse ig.data.style
document.getElementsByTagName 'head' .0.appendChild style
