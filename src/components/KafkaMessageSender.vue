<template>
  <div class="kafka-sender">
    <h2>Send Message to Kafka</h2>
    
    <!-- API Information -->
    <div class="api-info">
      <h3>API Configuration</h3>
      <div class="info-box">
        <p><strong>API URL:</strong> {{ apiUrl }}</p>
        <p><strong>Status:</strong> <span :class="['status-indicator', apiStatus]">{{ apiStatusText }}</span></p>
      </div>
    </div>

    <div class="message-form">
      <textarea
        v-model="message"
        placeholder="Enter your message here..."
        rows="4"
        class="message-input"
      ></textarea>
      <button @click="sendMessage" :disabled="isLoading" class="send-button">
        {{ isLoading ? 'Sending...' : 'Send Message' }}
      </button>
    </div>

    <!-- Response/Error Display -->
    <div v-if="response" :class="['response', response.success ? 'success' : 'error']">
      <div class="response-header">
        <strong>{{ response.success ? 'Success' : 'Error' }}</strong>
        <span class="timestamp">{{ response.timestamp }}</span>
      </div>
      <div class="response-message">{{ response.message }}</div>
      <div v-if="response.details" class="response-details">
        <pre>{{ JSON.stringify(response.details, null, 2) }}</pre>
      </div>
    </div>

    <!-- Debug Information -->
    <div v-if="debugInfo" class="debug-info">
      <h3>Debug Information</h3>
      <div class="info-box">
        <p><strong>Last Request:</strong> {{ debugInfo.lastRequest }}</p>
        <p><strong>Last Response:</strong> {{ debugInfo.lastResponse }}</p>
        <p><strong>Request Headers:</strong></p>
        <pre>{{ JSON.stringify(debugInfo.headers, null, 2) }}</pre>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'KafkaMessageSender',
  data() {
    return {
      message: '',
      isLoading: false,
      response: null,
      apiUrl: window.runtimeConfig?.VUE_APP_API_URL || 'Not configured',
      apiStatus: 'unknown',
      apiStatusText: 'Checking...',
      debugInfo: null
    }
  },
  created() {
    this.checkApiStatus()
  },
  methods: {
    async checkApiStatus() {
      try {
        const response = await fetch(`${this.apiUrl}/health`)
        this.apiStatus = response.ok ? 'online' : 'error'
        this.apiStatusText = response.ok ? 'Online' : 'Error'
      } catch (error) {
        this.apiStatus = 'error'
        this.apiStatusText = 'Offline'
      }
    },
    async sendMessage() {
      if (!this.message.trim()) {
        this.response = {
          success: false,
          message: 'Please enter a message',
          timestamp: new Date().toISOString()
        }
        return
      }

      this.isLoading = true
      this.response = null

      const headers = {
        'Content-Type': 'text/plain'
      }

      try {
        const response = await fetch(`${this.apiUrl}/send`, {
          method: 'POST',
          headers,
          body: this.message
        })

        // Update debug information
        this.debugInfo = {
          lastRequest: new Date().toISOString(),
          lastResponse: response.status,
          headers
        }

        if (response.ok) {
          this.response = {
            success: true,
            message: 'Message sent successfully!',
            timestamp: new Date().toISOString(),
            details: {
              status: response.status,
              statusText: response.statusText
            }
          }
          this.message = ''
        } else {
          const errorText = await response.text()
          throw new Error(`Server error: ${response.status} - ${errorText}`)
        }
      } catch (error) {
        this.response = {
          success: false,
          message: `Error: ${error.message}`,
          timestamp: new Date().toISOString(),
          details: {
            error: error.message,
            stack: error.stack
          }
        }
      } finally {
        this.isLoading = false
      }
    }
  }
}
</script>

<style scoped>
.kafka-sender {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

.api-info {
  margin-bottom: 20px;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 4px;
}

.info-box {
  background-color: white;
  padding: 15px;
  border-radius: 4px;
  border: 1px solid #dee2e6;
}

.status-indicator {
  display: inline-block;
  width: 10px;
  height: 10px;
  border-radius: 50%;
  margin-right: 5px;
}

.status-indicator.online {
  background-color: #28a745;
}

.status-indicator.error {
  background-color: #dc3545;
}

.status-indicator.unknown {
  background-color: #ffc107;
}

.message-form {
  display: flex;
  flex-direction: column;
  gap: 15px;
  margin: 20px 0;
}

.message-input {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 16px;
  resize: vertical;
}

.send-button {
  padding: 10px 20px;
  background-color: #42b983;
  color: white;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 16px;
  transition: background-color 0.3s;
}

.send-button:hover {
  background-color: #3aa876;
}

.send-button:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.response {
  margin-top: 20px;
  padding: 15px;
  border-radius: 4px;
}

.response-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.timestamp {
  font-size: 0.8em;
  color: #666;
}

.success {
  background-color: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.error {
  background-color: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.response-details {
  margin-top: 10px;
  padding: 10px;
  background-color: rgba(0, 0, 0, 0.05);
  border-radius: 4px;
}

.debug-info {
  margin-top: 30px;
  padding: 15px;
  background-color: #f8f9fa;
  border-radius: 4px;
}

.debug-info pre {
  background-color: #f8f9fa;
  padding: 10px;
  border-radius: 4px;
  overflow-x: auto;
  font-size: 0.9em;
}

@media (max-width: 768px) {
  .kafka-sender {
    padding: 10px;
  }
  
  .message-input {
    font-size: 14px;
  }
}
</style> 