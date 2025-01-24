import express, { Request, Response } from 'express';
import { createServer } from 'http';
import { WebSocket, WebSocketServer, RawData } from 'ws';

// Types
interface WebSocketMessage {
  type: string;
  payload: any;
}

// Express app
const app = express();
app.use(express.json());

app.get('/api/test', (req: Request, res: Response) => {
  res.json({ message: 'Success' });
});

app.get('/api/async_test', async (req: Request, res: Response) => {
  try {
    const result = await asyncFunction(); // Ta fonction asynchrone
    res.json({ message: 'Success', data: result });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    res.status(500).json({ message: 'Error', error: errorMessage });
  }
});

// Exemple de fonction asynchrone
async function asyncFunction(): Promise<any> {
  // Simulation d'une opération asynchrone (API call, DB query, etc.)
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({ someData: 'value' });
    }, 1000);
  });
}

// HTTP server
const server = createServer(app);

// WebSocket server
const wss = new WebSocketServer({ server });

wss.on('connection', (ws: WebSocket) => {
  console.log('Client connected');

  ws.on('message', (data: RawData) => {
    try {
      const message: WebSocketMessage = JSON.parse(data.toString());
      console.log('Received:', message);

      // Broadcast to all clients
      wss.clients.forEach((client) => {
        if (client !== ws && client.readyState === WebSocket.OPEN) {
          client.send(JSON.stringify(message));
        }
      });
    } catch (error) {
      console.error('Invalid message format:', error);
    }
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
