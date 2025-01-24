"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const http_1 = require("http");
const ws_1 = require("ws");
// Express app
const app = (0, express_1.default)();
app.use(express_1.default.json());
app.get('/api/test', (req, res) => {
    res.json({ message: 'Success' });
});
app.get('/api/async_test', (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const result = yield asyncFunction(); // Ta fonction asynchrone
        res.json({ message: 'Success', data: result });
    }
    catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        res.status(500).json({ message: 'Error', error: errorMessage });
    }
}));
// Exemple de fonction asynchrone
function asyncFunction() {
    return __awaiter(this, void 0, void 0, function* () {
        // Simulation d'une opération asynchrone (API call, DB query, etc.)
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({ someData: 'value' });
            }, 1000);
        });
    });
}
// HTTP server
const server = (0, http_1.createServer)(app);
// WebSocket server
const wss = new ws_1.WebSocketServer({ server });
wss.on('connection', (ws) => {
    console.log('Client connected');
    ws.on('message', (data) => {
        try {
            const message = JSON.parse(data.toString());
            console.log('Received:', message);
            // Broadcast to all clients
            wss.clients.forEach(client => {
                if (client !== ws && client.readyState === ws_1.WebSocket.OPEN) {
                    client.send(JSON.stringify(message));
                }
            });
        }
        catch (error) {
            console.error('Invalid message format:', error);
        }
    });
});
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
