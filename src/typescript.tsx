import * as React from 'react';
import * as ReactDOM from 'react-dom';

import { Minesweeper } from 'components/Minesweeper';

ReactDOM.render(
  <Minesweeper rows={10} columns={10} numBombs={10} />,
  document.getElementById('root'),
);
