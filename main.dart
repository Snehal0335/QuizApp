gitoops and argocd

  Search for argocd-example-apps on github then fork 

    minikube strat --driver=docker
    minikube status
    kubeclt get nodes
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    kubectl get pods -n argocd

      New power shell
Port forwarding
        kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
Go to browser
Test on browser http//localhost:8080
Generating the password  to get entry in the argocd web ui
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"


          paste this password in gui
          craete new app
          copy paste the github url
          














Wsdl database connection
  package server;

import java.sql.*;
import javax.jws.WebService;
import javax.jws.WebMethod;

@WebService(serviceName = "Curry_server")
public class Curry_server {

    public double getRate(String name) {

        double rate = 0;

        try {

            Connection con = DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/currency_db","root","");

            PreparedStatement ps = con.prepareStatement(
            "SELECT rate FROM currency WHERE name=?");

            ps.setString(1, name);

            ResultSet rs = ps.executeQuery();
            rs.next();

            rate = rs.getDouble("rate");

        } catch(Exception e) {
            System.out.println(e);
        }

        return rate;
    }

    @WebMethod
    public double rupeeToDollar(double rupee) {
        return rupee * getRate("Dollar");
    }

    @WebMethod
    public double rupeeToEuro(double rupee) {
        return rupee * getRate("Euro");
    }
}


