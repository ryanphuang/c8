// Generated by CoffeeScript 1.6.3
(function() {
  var CmdLine, Console, FileSys, Terminal, c8, fitCanvas, main, ms, redraw;

  c8 = new Object();

  main = function() {
    c8.cons = new CmdLine($("canvas#console"));
    redraw();
    $(document).keypress(function(ev) {
      if (ev.which === 13 || ev.which === 32) {
        ev.preventDefault();
      }
      if (ev.which >= 32 && ev.which <= 126) {
        c8.cons.insertChar(String.fromCharCode(ev.which));
      }
    });
    $(document).keydown(function(ev) {
      var _ref;
      if ((_ref = ev.which) === 8 || _ref === 46 || _ref === 13 || _ref === 37 || _ref === 39 || _ref === 9) {
        ev.preventDefault();
      }
      if (ev.which === 8) {
        c8.cons.backChar();
      }
      if (ev.which === 46) {
        c8.cons.delChar();
      }
      if (ev.which === 13) {
        c8.cons.enter();
      }
      if (ev.which === 37) {
        c8.cons.moveCurLeft();
      }
      if (ev.which === 39) {
        c8.cons.moveCurRight();
      }
      if (ev.which === 9) {
        return c8.cons.insertTab();
      }
    });
  };

  fitCanvas = function() {
    var c;
    c = $("canvas#console");
    c.height($(window).height() - 40);
  };

  redraw = function(timestamp) {
    fitCanvas();
    c8.cons.redraw();
    window.requestAnimationFrame(redraw);
  };

  ms = function() {
    return (new Date()).getMilliseconds();
  };

  Terminal = function(canvas) {
    var charHeight, charWidth, context, dpr, fontSize, height, lineHeight, lineMargin, ncol, nrow, self, width;
    self = this;
    dpr = window.devicePixelRatio;
    context = canvas.getContext('2d');
    context.scale(dpr, dpr);
    fontSize = 14 * dpr;
    charHeight = fontSize;
    lineMargin = 3 * dpr;
    lineHeight = charHeight + lineMargin;
    context.font = '' + fontSize + 'px Consolas';
    charWidth = context.measureText('M').width;
    width = 0;
    height = 0;
    nrow = 0;
    ncol = 0;
    self.sayHello = function() {
      var c, i, s, _i, _len, _ref;
      s = "j$ Hello world!";
      i = 0;
      _ref = s.split('');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        c = _ref[_i];
        self.drawChar(0, i, c);
        self.drawChar(1, i, c);
        i++;
      }
    };
    self.updateSize = function(w, h) {
      if (w === width && h === height) {
        return false;
      }
      canvas.width = w * dpr;
      canvas.height = h * dpr;
      context.font = '' + fontSize + 'px Consolas';
      context.fillStyle = '#ddd';
      context.textBaseline = 'bottom';
      width = w;
      height = h;
      nrow = Math.floor(height * dpr / lineHeight);
      ncol = Math.floor(width * dpr / charWidth);
      return true;
    };
    self.inRange = function(row, col) {
      if (row < 0) {
        return false;
      }
      if (row >= nrow) {
        return false;
      }
      if (col < 0) {
        return false;
      }
      if (col >= ncol) {
        return false;
      }
      return true;
    };
    self.charPos = function(row, col) {
      var x, y;
      x = col * charWidth;
      y = row * lineHeight + dpr;
      return {
        x: x,
        y: y
      };
    };
    self.clear = function() {
      context.clearRect(0, 0, width * dpr, height * dpr);
    };
    self.clearChar = function(row, col) {
      var p;
      if (!self.inRange(row, col)) {
        return;
      }
      p = self.charPos(row, col);
      context.clearRect(p.x, p.y, charWidth, charHeight);
    };
    self.clearLine = function(row) {
      var i, _i, _ref;
      for (i = _i = 0, _ref = ncol - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        self.clearChar(row, i);
      }
    };
    self.drawChar = function(row, col, c) {
      var p;
      if (!self.inRange(row, col)) {
        return;
      }
      p = self.charPos(row, col);
      context.clearRect(p.x, p.y, charWidth, charHeight);
      context.fillStyle = '#ddd';
      context.fillText(c, p.x, p.y + charHeight);
    };
    self.drawCursor = function(row, col) {
      var p;
      if (!self.inRange(row, col)) {
        return;
      }
      p = self.charPos(row, col);
      context.fillRect(p.x, p.y + charHeight, charWidth, dpr);
    };
    self.clearCursor = function(row, col) {
      var p;
      if (!self.inRange(row, col)) {
        return;
      }
      p = self.charPos(row, col);
      context.clearRect(p.x, p.y + charHeight, charWidth, dpr);
    };
    self.nrow = function() {
      return nrow;
    };
    self.ncol = function() {
      return ncol;
    };
  };

  Console = function(canvas) {
    var breakLine, lineNrow, self;
    self = this;
    self.term = new Terminal(canvas[0]);
    self.canvas = canvas;
    self.maxLines = 100000;
    self.lines = [];
    self.updated = true;
    self.lastLineHeight = 0;
    self.curPos = 0;
    self.curRow = 0;
    self.curCol = 0;
    self.curShow = false;
    self.drawCursor = function() {
      if (ms() < 500) {
        if (!self.curShow || self.updated) {
          self.term.drawCursor(self.curRow, self.curCol);
          self.curShow = true;
        }
      } else {
        if (self.curShow || self.updated) {
          self.term.clearCursor(self.curRow, self.curCol);
          self.curShow = false;
        }
      }
    };
    self.redraw = function() {
      var c, resized;
      c = self.canvas;
      resized = self.term.updateSize(c.width(), c.height());
      if (resized || self.updated) {
        self._redraw();
      } else {
        self.drawCursor();
      }
    };
    breakLine = function(line) {
      var chars, i, n, ncol, ret;
      chars = line.split('');
      n = chars.length;
      if (n === 0) {
        ret = [];
        ret.unshift([]);
        return ret;
      }
      ncol = self.term.ncol();
      i = 0;
      ret = [];
      while (i < n) {
        ret.unshift(chars.slice(i, i + ncol));
        i += ncol;
      }
      if (n % ncol === 0) {
        ret.unshift([]);
      }
      return ret;
    };
    lineNrow = function(line) {
      var ncol;
      ncol = self.term.ncol();
      if (ncol === 0) {
        return 0;
      }
      return Math.ceil((line.length + 1) / ncol);
    };
    self._redraw = function() {
      var b, buf, c, col, curRow, i, lastLine, lastLineHeight, lastNrow, line, n, ncol, nline, nrow, p, parts, row, term, _i, _j, _k, _l, _len, _len1, _len2, _len3, _len4, _m, _n, _ref;
      nrow = self.term.nrow();
      ncol = self.term.ncol();
      buf = [];
      lastLineHeight = 0;
      if (self.lines.length > 0) {
        lastLine = self.lines[0];
        lastNrow = lineNrow(lastLine);
        if (self.lastLineHeight > lastNrow) {
          n = self.lastLineHeight - lastNrow;
          if (n >= nrow) {
            n = nrow - 1;
          }
          for (i = _i = 1; 1 <= n ? _i <= n : _i >= n; i = 1 <= n ? ++_i : --_i) {
            buf.unshift([]);
            lastLineHeight++;
          }
        }
      }
      nline = self.lines.length;
      if (nline > 0) {
        lastLine = self.lines[0];
        parts = breakLine(lastLine);
        for (_j = 0, _len = parts.length; _j < _len; _j++) {
          p = parts[_j];
          buf.unshift(p);
          lastLineHeight++;
        }
        _ref = self.lines.slice(1, nline);
        for (_k = 0, _len1 = _ref.length; _k < _len1; _k++) {
          line = _ref[_k];
          if (buf.length >= nrow) {
            break;
          }
          parts = breakLine(line);
          for (_l = 0, _len2 = parts.length; _l < _len2; _l++) {
            p = parts[_l];
            buf.unshift(p);
            if (buf.length >= nrow) {
              break;
            }
          }
        }
      }
      while (buf.length > nrow && buf.length > lastLineHeight) {
        buf.shift();
      }
      term = self.term;
      term.clear();
      row = 0;
      for (_m = 0, _len3 = buf.length; _m < _len3; _m++) {
        b = buf[_m];
        col = 0;
        for (_n = 0, _len4 = b.length; _n < _len4; _n++) {
          c = b[_n];
          term.drawChar(row, col, c);
          col++;
        }
        row++;
      }
      curRow = Math.floor(self.curPos / ncol);
      self.curCol = self.curPos - curRow * ncol;
      self.curRow = buf.length - lastLineHeight + curRow;
      self.drawCursor();
      self.updated = false;
    };
    self.expandLastLineHeight = function(line) {
      var nrow;
      nrow = lineNrow(line);
      if (self.lastLineHeight < nrow) {
        return self.lastLineHeight = nrow;
      }
    };
    self.addLine = function(line) {
      var lastLine, lastLineHeight;
      if (self.lines.length > 0) {
        lastLine = self.lines[0];
        lastLineHeight = lineNrow(lastLine);
        if (self.lastLineHeight > lastLineHeight) {
          self.lastLineHeight -= lastLineHeight;
        } else {
          self.lastLineHeight = 0;
        }
      }
      self.lines.unshift(line);
      if (self.lines.length > self.maxLines) {
        self.lines.pop();
      }
      self.expandLastLineHeight(line);
      self.curPos = line.length;
      self.updated = true;
    };
    self.getLastLine = function() {
      var nline;
      nline = self.lines.length;
      if (nline === 0) {
        return '';
      }
      return self.lines[0];
    };
    self.setLastLine = function(s) {
      var nline;
      nline = self.lines.length;
      if (nline === 0) {
        self.addLine(s);
      } else {
        self.lines[0] = s;
        self.expandLastLineHeight(s);
      }
      self.updated = true;
    };
    self.setCursor = function(pos) {
      self.curPos = pos;
      self.updated = true;
    };
  };

  CmdLine = function(canvas) {
    var self;
    self = this;
    self.cons = new Console(canvas);
    self.prompt = '$ ';
    self.cons.addLine(self.prompt);
    self.line = '';
    self.curPos = 0;
    self.launcher = null;
    self.redraw = function() {
      self.cons.setLastLine(self.prompt + self.line);
      self.cons.setCursor(self.prompt.length + self.curPos);
      self.cons.redraw();
    };
    self.insertChar = function(c) {
      var after, before, line;
      line = self.line;
      before = line.substr(0, self.curPos);
      after = line.substr(self.curPos, line.length);
      self.line = before + c + after;
      self.curPos++;
    };
    self.insertTab = function() {
      self.insertChar(' ');
    };
    self.backChar = function(c) {
      var after, before, line;
      if (self.curPos > 0) {
        line = self.line;
        before = line.substr(0, self.curPos - 1);
        after = line.substr(self.curPos, line.length);
        self.line = before + after;
        self.curPos--;
      }
    };
    self.delChar = function(c) {
      var after, before, line, n;
      line = self.line;
      n = line.length;
      if (self.curPos !== n) {
        before = line.substr(0, self.curPos);
        after = line.substr(self.curPos + 1, line.length);
        self.line = before + after;
      }
    };
    self.moveCurLeft = function() {
      if (self.curPos > 0) {
        self.curPos--;
      }
    };
    self.moveCurRight = function() {
      if (self.curPos < self.line.length) {
        self.curPos++;
      }
    };
    self.enter = function() {
      if (self.line.length > 0) {
        self.launch(self.line);
      }
      self.cons.addLine(self.prompt);
      self.curPos = 0;
      self.line = '';
    };
    self.launch = function(line) {
      if (self.launcher === null) {
        return self.cons.addLine('You typed: ' + line);
      } else {
        return self.launcher.launch(line);
      }
    };
  };

  FileSys = function() {
    self.open = function(path) {};
    self.create = function(path) {};
    self.lsdir = function(path) {};
    self.mv = function(from, to) {};
    self.rm = function(path) {};
  };

  $(document).ready(main);

}).call(this);
