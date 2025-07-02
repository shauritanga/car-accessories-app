// Security & Access Control main component
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { detectFraud, getSecurityLogs } from './securityAccessService';
import { Box, Typography, Card, CardHeader, CardContent, Table, TableHead, TableRow, TableCell, TableBody, Chip, CircularProgress, Avatar } from '@mui/material';
import SecurityIcon from '@mui/icons-material/Security';
import WarningIcon from '@mui/icons-material/Warning';

const SecurityAccess = () => {
  // Fetch fraud/misuse cases
  const { data: fraudCases = [], isLoading: loadingFraud } = useQuery({
    queryKey: ['fraudCases'],
    queryFn: detectFraud,
  });
  // Fetch security logs
  const { data: logs = [], isLoading: loadingLogs } = useQuery({
    queryKey: ['securityLogs'],
    queryFn: getSecurityLogs,
  });

  if (loadingFraud || loadingLogs) return <CircularProgress />;

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" mb={3} color="primary.main">
        Security & Access Control
      </Typography>
      <Card sx={{ mb: 4, boxShadow: 3 }}>
        <CardHeader
          avatar={<Avatar sx={{ bgcolor: 'error.main' }}><WarningIcon /></Avatar>}
          title={<Typography variant="h6">Potential Fraud & Misuse</Typography>}
        />
        <CardContent>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>User</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Description</TableCell>
                <TableCell>Status</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {fraudCases.length === 0 && (
                <TableRow><TableCell colSpan={4}>No fraud or misuse detected</TableCell></TableRow>
              )}
              {fraudCases.map((item) => (
                <TableRow key={item.id}>
                  <TableCell>{item.userName}</TableCell>
                  <TableCell>{item.type}</TableCell>
                  <TableCell>{item.description}</TableCell>
                  <TableCell><Chip label={item.status} color={item.status === 'open' ? 'error' : 'success'} /></TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
      <Card sx={{ mb: 4, boxShadow: 3 }}>
        <CardHeader
          avatar={<Avatar sx={{ bgcolor: 'primary.main' }}><SecurityIcon /></Avatar>}
          title={<Typography variant="h6">Security Logs</Typography>}
        />
        <CardContent>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Timestamp</TableCell>
                <TableCell>User</TableCell>
                <TableCell>Action</TableCell>
                <TableCell>Result</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {logs.length === 0 && (
                <TableRow><TableCell colSpan={4}>No security logs found</TableCell></TableRow>
              )}
              {logs.map((log) => (
                <TableRow key={log.id}>
                  <TableCell>{log.timestamp}</TableCell>
                  <TableCell>{log.userName}</TableCell>
                  <TableCell>{log.action}</TableCell>
                  <TableCell><Chip label={log.result} color={log.result === 'success' ? 'success' : 'error'} /></TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </Box>
  );
};

export default SecurityAccess;
