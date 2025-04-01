<template>
  <div class="kafka-sender">
    <div class="container">
      <header class="app-header">
        <h1>Kafka Message Sender</h1>
        <div class="status-badges">
          <div class="status-badge" :class="configStatus">
            <span class="status-dot"></span>
            Config: {{ configStatusText }}
          </div>
          <div class="status-badge" :class="apiStatus">
            <span class="status-dot"></span>
            API: {{ apiStatusText }}
          </div>
        </div>
      </header>

      <div class="api-info card">
        <h3>API Configuration</h3>
        <div class="info-content">
          <div class="info-item">
            <label>API URL:</label>
            <code>{{ apiUrl }}</code>
          </div>
          <div v-if="configError" class="error-message">
            <i class="fas fa-exclamation-circle"></i>
            {{ configError }}
          </div>
        </div>
      </div>

      <div class="message-form card">
        <h3>Send Message</h3>
        <div class="form-content">
          <div class="input-group">
            <textarea
              v-model="message"
              placeholder="jeet Enter your message here..."
              rows="4"
              class="message-input"
              :class="{ 'error': messageError }"
              @input="validateMessage"
            ></textarea>
            <div class="input-feedback">
              <span class="char-count">{{ message.length }}/1000</span>
              <span v-if="messageError" class="error-text">{{ messageError }}</span>
            </div>
          </div>
          
          <button 
            @click="sendMessage" 
            :disabled="isLoading || !isConfigLoaded || !isValidMessage"
            class="send-button"
            :class="{ 'loading': isLoading }"
          >
            <span class="button-content">
              <i class="fas" :class="isLoading ? 'fa-spinner fa-spin' : 'fa-paper-plane'"></i>
              {{ isLoading ? 'Sending...' : 'Send Message' }}
            </span>
          </button>
        </div>
      </div>

      <div v-if="response" 
           class="response card"
           :class="response.success ? 'success' : 'error'"
           v-enter-animation>
        <div class="response-header">
          <div class="response-title">
            <i class="fas" :class="response.success ? 'fa-check-circle' : 'fa-exclamation-circle'"></i>
            {{ response.success ? 'Success' : 'Error' }}
          </div>
          <span class="timestamp">{{ formatTimestamp(response.timestamp) }}</span>
        </div>
        <div class="response-message">{{ response.message }}</div>
        <div v-if="response.details" class="response-details">
          <pre>{{ JSON.stringify(response.details, null, 2) }}</pre>
        </div>
      </div>

      <div v-if="debugInfo" class="debug-info card">
        <div class="debug-header">
          <h3>Debug Information</h3>
          <button class="toggle-button" @click="toggleDebug">
            <i class="fas" :class="showDebug ? 'fa-chevron-up' : 'fa-chevron-down'"></i>
          </button>
        </div>
        <div v-show="showDebug" class="debug-content">
          <div class="debug-section">
            <h4>Config Object</h4>
            <pre>{{ JSON.stringify(window.runtimeConfig, null, 2) }}</pre>
          </div>
          <div class="debug-section">
            <h4>Last Request</h4>
            <p>{{ debugInfo.lastRequest }}</p>
          </div>
          <div class="debug-section">
            <h4>Last Response</h4>
            <p>{{ debugInfo.lastResponse }}</p>
          </div>
          <div class="debug-section">
            <h4>Request Headers</h4>
            <pre>{{ JSON.stringify(debugInfo.headers, null, 2) }}</pre>
          </div>
        </div>
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
      apiUrl: 'http://kafka-producer-service-kafka.apps.okd4.elc.com',
      apiStatus: 'unknown',
      apiStatusText: 'Checking...',
      configStatus: 'success',
      configStatusText: 'Using fixed configuration',
      configError: null,
      isConfigLoaded: true,
      debugInfo: null,
      showDebug: false,
      messageError: '',
      isValidMessage: false
    }
  },
  created() {
    // Check API status on component creation
    this.checkApiStatus()
  },
  methods: {
    formatTimestamp(timestamp) {
      return new Date(timestamp).toLocaleString()
    },
    validateMessage() {
      if (this.message.length > 1000) {
        this.messageError = 'Message exceeds 1000 characters'
        this.isValidMessage = false
      } else if (!this.message.trim()) {
        this.messageError = 'Message cannot be empty'
        this.isValidMessage = false
      } else {
        this.messageError = ''
        this.isValidMessage = true
      }
    },
    toggleDebug() {
      this.showDebug = !this.showDebug
    },
    async checkApiStatus() {
      try {
        console.log('Checking API status at:', `${this.apiUrl}/health`)
        const response = await fetch(`${this.apiUrl}/health`, {
          method: 'GET',
          headers: {
            'Accept': 'application/json'
          }
        })
        console.log('Health check response:', response.status, response.statusText)
        this.apiStatus = response.ok ? 'online' : 'error'
        this.apiStatusText = response.ok ? 'Online' : `Error: ${response.status}`
      } catch (error) {
        console.error('Health check failed:', error)
        this.apiStatus = 'error'
        this.apiStatusText = `Offline: ${error.message}`
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
        'Content-Type': 'text/plain',
        'Accept': 'application/json'
      }

      try {
        console.log('Sending message to:', `${this.apiUrl}/send`)
        const response = await fetch(`${this.apiUrl}/send`, {
          method: 'POST',
          headers,
          body: this.message
        })

        // Update debug information
        this.debugInfo = {
          lastRequest: new Date().toISOString(),
          lastResponse: response.status,
          headers,
          requestUrl: `${this.apiUrl}/send`
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
        console.error('Send message failed:', error)
        this.response = {
          success: false,
          message: `Error: ${error.message}`,
          timestamp: new Date().toISOString(),
          details: {
            error: error.message,
            stack: error.stack,
            url: `${this.apiUrl}/send`
          }
        }
      } finally {
        this.isLoading = false
      }
    }
  },
  directives: {
    enterAnimation: {
      inserted: function(el) {
        el.style.opacity = '0'
        el.style.transform = 'translateY(20px)'
        setTimeout(() => {
          el.style.transition = 'all 0.3s ease'
          el.style.opacity = '1'
          el.style.transform = 'translateY(0)'
        }, 50)
      }
    }
  }
}
</script>

<style scoped>
.kafka-sender {
  min-height: 100vh;
  background-color: #f5f7fa;
  padding: 2rem;
}

.container {
  max-width: 800px;
  margin: 0 auto;
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.app-header h1 {
  color: #2c3e50;
  margin: 0;
  font-size: 2rem;
}

.status-badges {
  display: flex;
  gap: 1rem;
}

.status-badge {
  display: flex;
  align-items: center;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.9rem;
  background-color: #fff;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 0.5rem;
}

.status-badge.online .status-dot {
  background-color: #42b983;
}

.status-badge.error .status-dot {
  background-color: #dc3545;
}

.status-badge.unknown .status-dot {
  background-color: #ffc107;
}

.card {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  padding: 1.5rem;
  margin-bottom: 1.5rem;
}

.card h3 {
  color: #2c3e50;
  margin-top: 0;
  margin-bottom: 1rem;
}

.info-content {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.info-item label {
  font-weight: 600;
  color: #666;
}

.info-item code {
  background: #f8f9fa;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-family: monospace;
}

.message-form {
  margin-top: 2rem;
}

.input-group {
  position: relative;
  margin-bottom: 1rem;
}

.message-input {
  width: 100%;
  padding: 1rem;
  border: 2px solid #e9ecef;
  border-radius: 8px;
  font-size: 1rem;
  resize: vertical;
  min-height: 120px;
  transition: all 0.3s ease;
}

.message-input:focus {
  outline: none;
  border-color: #42b983;
  box-shadow: 0 0 0 3px rgba(66, 185, 131, 0.1);
}

.message-input.error {
  border-color: #dc3545;
}

.input-feedback {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 0.5rem;
  font-size: 0.9rem;
}

.char-count {
  color: #666;
}

.error-text {
  color: #dc3545;
}

.send-button {
  width: 100%;
  padding: 1rem;
  background-color: #42b983;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.5rem;
}

.send-button:hover:not(:disabled) {
  background-color: #3aa876;
  transform: translateY(-1px);
}

.send-button:disabled {
  background-color: #cccccc;
  cursor: not-allowed;
}

.send-button.loading {
  cursor: wait;
}

.button-content {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.response {
  margin-top: 1.5rem;
  transition: all 0.3s ease;
}

.response-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.response-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
}

.timestamp {
  font-size: 0.9rem;
  color: #666;
}

.response.success {
  background-color: #d4edda;
  border: 1px solid #c3e6cb;
}

.response.error {
  background-color: #f8d7da;
  border: 1px solid #f5c6cb;
}

.response-details {
  margin-top: 1rem;
  padding: 1rem;
  background-color: rgba(0, 0, 0, 0.05);
  border-radius: 4px;
  overflow-x: auto;
}

.debug-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.toggle-button {
  background: none;
  border: none;
  color: #666;
  cursor: pointer;
  padding: 0.5rem;
  transition: transform 0.3s ease;
}

.toggle-button:hover {
  color: #2c3e50;
}

.debug-content {
  margin-top: 1rem;
}

.debug-section {
  margin-bottom: 1.5rem;
}

.debug-section h4 {
  color: #666;
  margin-bottom: 0.5rem;
}

.debug-section pre {
  background: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
  overflow-x: auto;
  font-size: 0.9rem;
}

@media (max-width: 768px) {
  .kafka-sender {
    padding: 1rem;
  }

  .app-header {
    flex-direction: column;
    gap: 1rem;
    text-align: center;
  }

  .status-badges {
    flex-direction: column;
  }

  .info-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
}
</style> 