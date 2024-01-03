const Printer = {};
$(document).ready(function () {
    window.addEventListener('message', function (event) {
        const action = event.data.action;

        switch (action) {
            case "openDocument":
                Printer.openDocument(event.data);
                break;
            case "startPrinting":
                $(".printer-container").fadeIn(1000);
                break;
            case "closeDocument":
                Printer.closeDocument();
                break;
        }
    });

    $('.cancel-document').click(function () {
        Printer.closeDocument()
    });

    $('.printer-accept').click(function () {
        Printer.saveDocument();
        $(".printer-container, .document-container").fadeOut(1000);
        Printer.closeDocument();
    });

    $('.printer-decline').click(function () {
        Printer.closeDocument();
    });

    $(document).keydown(function (event) {
        switch (event.key) {
            case "Escape":
                Printer.closeDocument();
                break;
            case "Tab":
                Printer.closeDocument();
                break;
        }
    });
});
 
Printer.closeDocument = function (data) {
    $(".printer-container, .document-container").fadeOut(1000);
    $.post(`https://${GetParentResourceName()}/closeDocument`, JSON.stringify({
        url: $('.printer-input').val(),
        ...data
    }));

}
    
Printer.openDocument = function (data) {
    if (data.url) {
        $(".document-container").fadeIn(1000);
        $(".document-image").attr('src', data.url);
        $.post(`https://${GetParentResourceName()}/openedDocument`);
    } else {
        console.log('Image URL is invalid. Please let a developer know of this bug');
    }
};

Printer.saveDocument = function (data = {}) {
    $.post(`https://${GetParentResourceName()}/saveDocument`, JSON.stringify({
        url: $('.printer-input').val(),
        ...data
    }));
};
