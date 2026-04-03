import express from 'express';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';

const app = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Base Check
app.get('/', (req, res) => {
  res.send('API de synchronisation Étude en ligne !');
});

// Endpoint de Synchronisation
app.post('/api/sync', async (req, res) => {
  const { lastSyncTime, data } = req.body;
  const { students, groups, payments, scheduleSlots } = data;

  try {
    // 1. Recevoir les données "Modifiées" de l'application et les sauvegarder
    
    // Étudiants
    if (students && students.length > 0) {
      for (const s of students) {
        await prisma.student.upsert({
          where: { id: s.id },
          create: {
            id: s.id,
            name: s.name,
            phone: s.phone,
            sessionsSincePayment: s.sessionsSincePayment,
            pricePerCycle: s.pricePerCycle,
            monthlyExpiry: s.monthlyExpiry ? new Date(s.monthlyExpiry) : null,
            groupId: s.groupId,
            paymentMode: s.paymentMode,
            updatedAt: new Date(),
          },
          update: {
            name: s.name,
            phone: s.phone,
            sessionsSincePayment: s.sessionsSincePayment,
            pricePerCycle: s.pricePerCycle,
            monthlyExpiry: s.monthlyExpiry ? new Date(s.monthlyExpiry) : null,
            groupId: s.groupId,
            paymentMode: s.paymentMode,
            updatedAt: new Date(),
          }
        });
      }
    }

    // 2. Chercher les données modifiées sur le Serveur DEPUIS le dernier sync de cette App
    const syncDate = lastSyncTime ? new Date(lastSyncTime) : new Date(0);

    const updatedStudents = await prisma.student.findMany({
      where: { updatedAt: { gt: syncDate } }
    });

    // Envoyer la réponse avec ce qu'il faut télécharger sur le Tel
    res.json({
      success: true,
      timestamp: new Date().toISOString(),
      downloads: {
        students: updatedStudents,
      }
    });

  } catch (error) {
    console.error('Erreur Sync:', error);
    res.status(500).json({ error: 'Erreur lors de la synchronisation serveur.' });
  }
});

app.listen(PORT, () => {
  console.log(`Serveur de synchronisation Étude démarré sur http://localhost:${PORT}`);
});
