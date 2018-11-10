"use strict";

require("./styles.scss");

import {dispatcher} from './FileReader'

const { Elm } = require("./Main");
var app = Elm.Main.init({ flags: 6 });

app.ports.toJs.subscribe(data => {
    // debugger;
    dispatcher(data, app.ports.fromJs.send);
});
